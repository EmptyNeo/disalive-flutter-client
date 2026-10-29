import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/calls/pip_service.dart';
import 'package:disalive/presentation/features/calls/bloc/call_bloc.dart';
import 'package:disalive/presentation/features/calls/call_pip_overlay.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/invites/invite_server_screen.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class CallScreen extends StatefulWidget {
  static final ValueNotifier<int> exitRevision = ValueNotifier<int>(0);

  const CallScreen({
    super.key,
    required this.chatId,
    required this.entityKey,
    required this.title,
    this.lastIdMessage,
    this.canOpenInvite = false,
  });

  final int chatId;
  final EntityKey entityKey;
  final String title;
  final int? lastIdMessage;
  final bool canOpenInvite;

  static T? _optionalBloc<T extends StateStreamableSource<Object?>>(
    BuildContext context,
  ) {
    try {
      return context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  static Future<void> open(
    BuildContext context, {
    required int chatId,
    required EntityKey entityKey,
    required String title,
    int? lastIdMessage,
    CallBloc? callBloc,
    ChatBloc? chatBloc,
    ServersBloc? serversBloc,
    MessageBloc? messageBloc,
    InvitesBloc? invitesBloc,
    bool announceCall = true,
  }) {
    final navigator = Navigator.of(context);
    final bloc = callBloc ?? context.read<CallBloc>();
    final scopedChatBloc = chatBloc ?? _optionalBloc<ChatBloc>(context);
    final scopedServersBloc =
        serversBloc ?? _optionalBloc<ServersBloc>(context);
    final scopedMessageBloc =
        messageBloc ?? _optionalBloc<MessageBloc>(context);
    final scopedInvitesBloc =
        invitesBloc ?? _optionalBloc<InvitesBloc>(context);
    final active =
        bloc.state.status == CallStatus.connecting ||
        bloc.state.status == CallStatus.connected;
    final currentChatId = active ? bloc.state.chatId ?? chatId : chatId;
    final currentEntityKey = active
        ? bloc.state.entityKey ?? entityKey
        : entityKey;
    final currentTitle = active ? bloc.state.title ?? title : title;
    CallPipOverlay.configure(
      context,
      bloc,
      onOpen: (overlayContext) {
        final state = bloc.state;
        open(
          overlayContext,
          chatId: state.chatId ?? chatId,
          entityKey: state.entityKey ?? entityKey,
          title: state.title ?? title,
          callBloc: bloc,
          chatBloc: scopedChatBloc,
          serversBloc: scopedServersBloc,
          messageBloc: scopedMessageBloc,
          invitesBloc: scopedInvitesBloc,
        );
      },
    );
    CallPipOverlay.setScreenVisible(true);
    if (!active) {
      bloc.add(
        JoinCall(
          chatId: chatId,
          entityKey: entityKey,
          title: title,
          lastIdMessage: lastIdMessage,
          announceCall: announceCall,
        ),
      );
    }
    return navigator.push(
      CupertinoPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            if (scopedChatBloc != null)
              BlocProvider.value(value: scopedChatBloc),
            if (scopedServersBloc != null)
              BlocProvider.value(value: scopedServersBloc),
            if (scopedMessageBloc != null)
              BlocProvider.value(value: scopedMessageBloc),
            if (scopedInvitesBloc != null)
              BlocProvider.value(value: scopedInvitesBloc),
          ],
          child: CallScreen(
            chatId: currentChatId,
            entityKey: currentEntityKey,
            title: currentTitle,
            lastIdMessage: lastIdMessage,
            canOpenInvite:
                scopedChatBloc != null &&
                scopedMessageBloc != null &&
                scopedInvitesBloc != null &&
                (currentEntityKey.entityType != EntityType.server ||
                    scopedServersBloc != null),
          ),
        ),
      ),
    );
  }

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static int _systemUiEpoch = 0;

  String? _focusedTileId;
  String? _fullscreenTileId;
  final Map<String, GlobalKey> _tileKeys = {};
  final GlobalKey _controlsKey = GlobalKey();
  double _controlsHeight = 112;
  bool _exiting = false;
  bool _closingScreen = false;
  bool _allowPop = false;
  bool _overlaysVisible = true;
  bool _offeredPipSettings = false;
  Timer? _overlayTimer;
  late final int _ownSystemUiEpoch;
  Future<void>? _restoreSystemUiFuture;

  bool get _canCreateCallInvite {
    if (widget.entityKey.entityType == EntityType.server) {
      if (!sl.isRegistered<ServerRepository>()) return false;
      final server = sl<ServerRepository>().getByIdCached(
        widget.entityKey.entityId,
      );
      return server != null &&
          (server.isServerOwner ||
              server.hasPermission(ServerPermissions.manageInvites));
    }
    if (!sl.isRegistered<ChatRepository>()) return false;
    final chats = sl<ChatRepository>().getCached();
    final chat = chats.where((item) => item.id == widget.chatId).firstOrNull;
    return chat != null &&
        (chat.isOwner ||
            chat.role?.hasPermission(ChatPermissions.manageInvites) == true ||
            chat.member?.role?.hasPermission(ChatPermissions.manageInvites) ==
                true);
  }

  Widget _inviteButton() {
    if (!widget.canOpenInvite || !_canCreateCallInvite) {
      return const SizedBox.shrink();
    }
    return CupertinoButton(
      key: const ValueKey('invite_to_call'),
      padding: EdgeInsets.zero,
      minimumSize: const Size(40, 40),
      onPressed: () => InviteServerScreen.openCall(
        context,
        entityKey: widget.entityKey,
        targetChatId: widget.chatId,
        title: widget.title,
      ),
      child: const Icon(
        CupertinoIcons.person_add,
        color: CupertinoColors.white,
        size: 22,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ownSystemUiEpoch = ++_systemUiEpoch;
    _focusedTileId = CallPipOverlay.selectedTileId;
    _scheduleOverlayHide();
    if (Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallPipOverlay.setScreenVisible(false);
    });
    unawaited(_restoreSystemUi());
    CallScreen.exitRevision.value++;
    super.dispose();
  }

  Future<void> _restoreSystemUi() =>
      _restoreSystemUiFuture ??= _doRestoreSystemUi();

  Future<void> _doRestoreSystemUi() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } on PlatformException catch (error) {
      debugPrint('Failed to restore system UI after call: $error');
    }
    if (Platform.isAndroid) {
      // Android may ignore a system bar change made shortly after another one.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 1100), () async {
          if (_systemUiEpoch == _ownSystemUiEpoch) {
            try {
              await SystemChrome.restoreSystemUIOverlays();
            } on PlatformException catch (error) {
              debugPrint('Failed to reapply system UI after call: $error');
            }
          }
        }),
      );
    }
  }

  Future<void> _closeScreen() async {
    if (_closingScreen || !mounted) return;
    _closingScreen = true;
    await _restoreSystemUi();
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _scheduleOverlayHide() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_exiting) setState(() => _overlaysVisible = false);
    });
  }

  void _showOverlays() {
    if (!_overlaysVisible) setState(() => _overlaysVisible = true);
    _scheduleOverlayHide();
  }

  void _leave() {
    if (_exiting) return;
    _exiting = true;
    context.read<CallBloc>().add(const LeaveCall());
  }

  Future<void> _offerPipSettings() async {
    if (!Platform.isAndroid || !await PipService.isSupported) return;
    if (await PipService.isAllowed) return;
    if (!mounted ||
        _exiting ||
        _allowPop ||
        PipService.isInPipMode.value ||
        context.read<CallBloc>().state.status != CallStatus.connected) {
      return;
    }
    final openSettings = await showConfirmationDialog(
      context,
      title: 'Разрешить картинку в картинке',
      description:
          'Чтобы видеть звонок поверх других приложений, включите «Картинка в картинке» в настройках Disalive. Звонок продолжится и без этого разрешения.',
      confirmText: 'Открыть настройки',
      cancelText: 'Позже',
    );
    if (openSettings == true) await PipService.openSettings();
  }

  void _minimize() {
    if (_exiting || _closingScreen) return;
    CallPipOverlay.select(_fullscreenTileId ?? _focusedTileId);
    CallPipOverlay.setScreenVisible(false);
    unawaited(_closeScreen());
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _minimize();
    },
    child: BlocListener<CallBloc, CallState>(
      listenWhen: (old, next) => old.status != next.status,
      listener: (context, state) {
        if (state.status == CallStatus.connected && !_offeredPipSettings) {
          _offeredPipSettings = true;
          unawaited(_offerPipSettings());
        }
        if (state.status == CallStatus.left && mounted) {
          unawaited(_closeScreen());
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF101116),
        child: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) => ValueListenableBuilder<bool>(
            valueListenable: PipService.isInPipMode,
            builder: (context, inPip, _) =>
                inPip ? const SizedBox.expand() : _buildContent(state),
          ),
        ),
      ),
    ),
  );

  Widget _buildContent(CallState state) {
    _measureControlsHeight();
    final tiles = _tilesForRoom(state.room);
    final focused = tiles
        .where((tile) => tile.id == _focusedTileId)
        .firstOrNull;
    final fullscreen = tiles
        .where((tile) => tile.id == _fullscreenTileId)
        .firstOrNull;
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          top: 0,
          left: 0,
          right: 0,
          bottom: (focused != null || fullscreen != null) && _overlaysVisible
              ? _controlsHeight
              : 0,
          child: state.status == CallStatus.connected
              ? (fullscreen != null
                    ? _tile(fullscreen, state, fullScreen: true)
                    : focused == null
                    ? _grid(tiles, state)
                    : _focusedView(focused, tiles, state))
              : _statusView(state),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !_overlaysVisible,
            child: AnimatedOpacity(
              opacity: _overlaysVisible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: _header(
                (state.room?.remoteParticipants.length ?? 0) +
                    (state.room?.localParticipant == null ? 0 : 1),
                tileForFullscreen: fullscreen ?? focused,
                isFullscreen: fullscreen != null,
              ),
            ),
          ),
        ),
        if (state.error != null && state.status == CallStatus.connected)
          Positioned(
            top: 82,
            left: 20,
            right: 20,
            child: _errorBanner(state.error!),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !_overlaysVisible,
            child: AnimatedOpacity(
              opacity: _overlaysVisible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: SizedBox(key: _controlsKey, child: _controls(state)),
            ),
          ),
        ),
        if (!_overlaysVisible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: Semantics(
              button: true,
              label: 'Показать управление звонком',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showOverlays,
                child: const SizedBox.expand(),
              ),
            ),
          ),
      ],
    );
  }

  void _measureControlsHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = _controlsKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final height = renderObject.size.height;
      if ((height - _controlsHeight).abs() > 0.5) {
        setState(() => _controlsHeight = height);
      }
    });
  }

  void _toggleFullscreen(String tileId) {
    setState(() {
      _fullscreenTileId = _fullscreenTileId == tileId ? null : tileId;
    });
    CallPipOverlay.select(tileId);
    _showOverlays();
  }

  List<_CallTile> _tilesForRoom(lk.Room? room) {
    if (room == null) return const [];
    final participants = <lk.Participant>[
      if (room.localParticipant != null) room.localParticipant!,
      ...room.remoteParticipants.values,
    ];
    final tiles = <_CallTile>[];
    for (final participant in participants) {
      final camera = participant.getTrackPublicationBySource(
        lk.TrackSource.camera,
      );
      final cameraTrack =
          camera?.muted == false && camera?.track is lk.VideoTrack
          ? camera!.track as lk.VideoTrack
          : null;
      tiles.add(
        _CallTile(
          participant: participant,
          type: cameraTrack == null
              ? CallTrackType.audio
              : CallTrackType.camera,
          track: cameraTrack,
        ),
      );
      final screen = participant.getTrackPublicationBySource(
        lk.TrackSource.screenShareVideo,
      );
      if (screen?.muted == false && screen?.track is lk.VideoTrack) {
        tiles.add(
          _CallTile(
            participant: participant,
            type: CallTrackType.screenshare,
            track: screen!.track as lk.VideoTrack,
          ),
        );
      }
    }
    return tiles;
  }

  Widget _grid(List<_CallTile> tiles, CallState state) {
    if (tiles.isEmpty) return const Center(child: CupertinoActivityIndicator());
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = tiles.length;
        final columns = count == 1 || (count == 2 && constraints.maxWidth < 700)
            ? 1
            : math.min(count, constraints.maxWidth >= 700 ? 3 : 2);
        final rows = (count / columns).ceil();
        final usableHeight = math.max(120.0, constraints.maxHeight - 16);
        final tileWidth =
            (constraints.maxWidth - 16 - (columns - 1) * 8) / columns;
        final rowHeight = (usableHeight - (rows - 1) * 8) / rows;
        final tileHeight = count == 1
            ? usableHeight
            : math.min(rowHeight, tileWidth * (columns == 1 ? 0.85 : 1.05));
        final gridHeight = rows * tileHeight + (rows - 1) * 8;
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: SizedBox(
              height: math.min(usableHeight, gridHeight),
              child: GridView.builder(
                itemCount: count,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: tileWidth / tileHeight,
                ),
                itemBuilder: (context, index) => _tile(tiles[index], state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _focusedView(
    _CallTile focused,
    List<_CallTile> tiles,
    CallState state,
  ) {
    final others = tiles.where((tile) => tile.id != focused.id).toList();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(child: _tile(focused, state)),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: others.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    SizedBox(width: 138, child: _tile(others[index], state)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile(_CallTile tile, CallState state, {bool fullScreen = false}) {
    final participant = tile.participant;
    final isSelf =
        participant.identity == state.room?.localParticipant?.identity;
    final microphone = participant.getTrackPublicationBySource(
      lk.TrackSource.microphone,
    );
    final micOn = microphone != null && !microphone.muted;
    final mutedLocally = state.locallyMutedParticipants.contains(
      participant.identity,
    );
    final metadata = _metadata(participant.metadata);
    final name =
        (metadata['displayName'] ??
                metadata['username'] ??
                (participant.name.isEmpty
                    ? participant.identity
                    : participant.name))
            .toString();
    final avatar = Domain.transformUrl(
      (metadata['pathImage'] ?? metadata['pathAvatar'])?.toString(),
    );
    final isFocused = _focusedTileId == tile.id;
    return ClipRRect(
      key: _tileKeys.putIfAbsent(tile.id, () => GlobalKey()),
      borderRadius: BorderRadius.circular(fullScreen ? 0 : 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF252731),
          border: Border.all(
            color: participant.isSpeaking
                ? AppColors.green
                : const Color(0xFF40424C),
            width: participant.isSpeaking ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(fullScreen ? 0 : 18),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tile.track != null)
              lk.VideoTrackRenderer(
                tile.track!,
                fit: tile.type == CallTrackType.screenshare
                    ? lk.VideoViewFit.contain
                    : lk.VideoViewFit.cover,
              )
            else
              Center(child: BuildAvatar(url: avatar, wh: 76, size: 32)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 66,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xC9000000)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: fullScreen
                    ? _showOverlays
                    : () {
                        setState(
                          () => _focusedTileId = isFocused ? null : tile.id,
                        );
                        CallPipOverlay.select(_focusedTileId);
                      },
              ),
            ),
            Positioned(
              left: 10,
              right: 8,
              bottom: 9,
              child: Row(
                children: [
                  Icon(
                    tile.type == CallTrackType.screenshare
                        ? CupertinoIcons.rectangle_on_rectangle
                        : (micOn
                              ? CupertinoIcons.mic_fill
                              : CupertinoIcons.mic_slash_fill),
                    size: 15,
                    color: micOn ? CupertinoColors.white : AppColors.errorRed,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSelf ? '$name (вы)' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (state.headsetStates[participant.identity] == false)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        CupertinoIcons.volume_off,
                        size: 14,
                        color: AppColors.errorRed,
                      ),
                    ),
                  if (!isSelf)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(30, 30),
                      onPressed: () => context.read<CallBloc>().add(
                        ToggleParticipantAudio(participant.identity),
                      ),
                      child: Icon(
                        mutedLocally
                            ? CupertinoIcons.speaker_slash_fill
                            : CupertinoIcons.speaker_2_fill,
                        size: 16,
                        color: mutedLocally
                            ? AppColors.errorRed
                            : CupertinoColors.white,
                      ),
                    ),
                ],
              ),
            ),
            if (tile.type == CallTrackType.screenshare)
              Positioned(top: 10, left: 10, child: _tag('ЭКРАН')),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.blurple,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    ),
  );

  Map<String, dynamic> _metadata(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, dynamic>.from(value) : const {};
    } catch (_) {
      return const {};
    }
  }

  Widget _header(
    int count, {
    _CallTile? tileForFullscreen,
    required bool isFullscreen,
  }) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xD9000000), Color(0x00000000)],
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: _minimize,
              child: const Icon(
                CupertinoIcons.chevron_back,
                color: CupertinoColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: EmojiTextParser.parse(
                        widget.title,
                        emojiSize: 19,
                        animateEmoji: false,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                  Text(
                    '$count в звонке',
                    style: const TextStyle(
                      color: Color(0xFFB6B8C2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.canOpenInvite &&
                widget.entityKey.entityType == EntityType.server &&
                sl.isRegistered<ServerRepository>())
              BlocBuilder<ServersBloc, ServersState>(
                builder: (_, _) => _inviteButton(),
              )
            else if (widget.canOpenInvite &&
                widget.entityKey.entityType == EntityType.chat &&
                sl.isRegistered<ChatRepository>())
              BlocBuilder<ChatBloc, ChatState>(
                builder: (_, _) => _inviteButton(),
              ),
            if (tileForFullscreen != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 40),
                onPressed: () => _toggleFullscreen(tileForFullscreen.id),
                child: Semantics(
                  label: isFullscreen
                      ? 'Свернуть плитку'
                      : 'Развернуть плитку на весь экран',
                  child: Icon(
                    isFullscreen
                        ? CupertinoIcons.arrow_down_right_arrow_up_left
                        : CupertinoIcons.arrow_up_left_arrow_down_right,
                    color: CupertinoColors.white,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _statusView(CallState state) => state.status == CallStatus.left
      ? const SizedBox.shrink()
      : Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.status == CallStatus.failed)
                  const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    size: 36,
                    color: AppColors.errorRed,
                  )
                else
                  const CupertinoActivityIndicator(radius: 16),
                const SizedBox(height: 16),
                Text(
                  state.status == CallStatus.failed
                      ? state.error ?? 'Не удалось подключиться к звонку'
                      : state.status == CallStatus.leaving
                      ? 'Завершаем звонок…'
                      : 'Подключаемся к звонку…',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 15,
                  ),
                ),
                if (state.status == CallStatus.failed) ...[
                  const SizedBox(height: 18),
                  CupertinoButton.filled(
                    onPressed: () => context.read<CallBloc>().add(
                      JoinCall(
                        chatId: widget.chatId,
                        entityKey: widget.entityKey,
                        title: widget.title,
                        lastIdMessage: widget.lastIdMessage,
                      ),
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ],
            ),
          ),
        );

  Widget _errorBanner(String error) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF56242A),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        error,
        style: const TextStyle(color: CupertinoColors.white, fontSize: 12),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );

  Widget _controls(CallState state) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xEB22232B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF393B45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: _control(
                  CupertinoIcons.mic_fill,
                  active: state.microphoneEnabled,
                  label: 'Микрофон',
                  onTap: () => context.read<CallBloc>().add(
                    const ToggleCallMicrophone(),
                  ),
                ),
              ),
              Expanded(
                child: _control(
                  state.outputEnabled
                      ? CupertinoIcons.headphones
                      : CupertinoIcons.speaker_slash_fill,
                  active: state.outputEnabled,
                  label: 'Звук',
                  onTap: () =>
                      context.read<CallBloc>().add(const ToggleCallOutput()),
                ),
              ),
              Expanded(
                child: _control(
                  CupertinoIcons.videocam_fill,
                  active: state.cameraEnabled,
                  label: 'Камера',
                  onTap: () =>
                      context.read<CallBloc>().add(const ToggleCallCamera()),
                ),
              ),
              Expanded(
                child: _control(
                  CupertinoIcons.switch_camera,
                  active: state.cameraEnabled,
                  label: 'Повернуть',
                  onTap: state.cameraEnabled
                      ? () => context.read<CallBloc>().add(
                          const SwitchCallCamera(),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: _control(
                  CupertinoIcons.rectangle_on_rectangle,
                  active: state.screenShareEnabled,
                  label: 'Экран',
                  onTap: () => context.read<CallBloc>().add(
                    const ToggleCallScreenShare(),
                  ),
                ),
              ),
              Expanded(
                child: _control(
                  CupertinoIcons.phone_down_fill,
                  active: true,
                  label: 'Выйти',
                  destructive: true,
                  onTap: _leave,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _control(
    IconData icon, {
    required bool active,
    required String label,
    required VoidCallback? onTap,
    bool destructive = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final diameter = math.min(42.0, math.max(24.0, constraints.maxWidth - 2));
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onTap == null
            ? null
            : () {
                _showOverlays();
                onTap();
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: diameter,
              height: diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: destructive
                    ? AppColors.errorRed
                    : active
                    ? const Color(0xFF464956)
                    : const Color(0xFF343640),
              ),
              child: Icon(
                icon,
                size: 20,
                color: onTap == null
                    ? const Color(0xFF777984)
                    : CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD5D5DA), fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    },
  );
}

class _CallTile {
  const _CallTile({required this.participant, required this.type, this.track});
  final lk.Participant participant;
  final CallTrackType type;
  final lk.VideoTrack? track;
  String get id =>
      '${participant.identity}:${type == CallTrackType.screenshare ? 'screen' : 'primary'}';
}
