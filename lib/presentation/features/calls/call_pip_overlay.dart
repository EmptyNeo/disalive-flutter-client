import 'dart:async';
import 'dart:convert';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/services/calls/pip_service.dart';
import 'package:disalive/presentation/features/calls/bloc/call_bloc.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// Draws a small in-app call window, or a video-only surface for Android PiP.
class CallPipOverlay {
  CallPipOverlay._();

  static OverlayState? _overlay;
  static OverlayEntry? _entry;
  static CallBloc? _bloc;
  static StreamSubscription<CallState>? _subscription;
  static void Function(BuildContext)? _onOpen;
  static bool _screenVisible = false;
  static String? selectedTileId;

  static void configure(
    BuildContext context,
    CallBloc bloc, {
    required void Function(BuildContext) onOpen,
  }) {
    PipService.initialize();
    _overlay = Overlay.of(context, rootOverlay: true);
    _onOpen = onOpen;
    if (!identical(_bloc, bloc)) {
      _subscription?.cancel();
      _bloc = bloc;
      _subscription = bloc.stream.listen((state) {
        if (state.status == CallStatus.left ||
            state.status == CallStatus.failed) {
          selectedTileId = null;
          _remove();
        } else {
          _sync();
        }
      });
    }
    PipService.isInPipMode.removeListener(_sync);
    PipService.isInPipMode.addListener(_sync);
    _sync();
  }

  static void setScreenVisible(bool visible) {
    if (_screenVisible == visible) return;
    _screenVisible = visible;
    _sync();
  }

  static void select(String? tileId) {
    selectedTileId = tileId;
    _entry?.markNeedsBuild();
  }

  static void _sync() {
    final status = _bloc?.state.status;
    final active =
        status == CallStatus.connecting ||
        status == CallStatus.connected ||
        status == CallStatus.leaving;
    if (!active || (_screenVisible && !PipService.isInPipMode.value)) {
      _remove();
      return;
    }
    if (_entry == null) {
      _entry = OverlayEntry(builder: _build);
      _overlay?.insert(_entry!);
    } else {
      _entry!.markNeedsBuild();
    }
  }

  static Widget _build(BuildContext context) {
    final bloc = _bloc;
    if (bloc == null) return const SizedBox.shrink();
    return BlocBuilder<CallBloc, CallState>(
      bloc: bloc,
      builder: (context, state) {
        if (state.status != CallStatus.connected) {
          return const SizedBox.shrink();
        }
        if (PipService.isInPipMode.value) {
          return Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF101116),
              child: _CallPipTile(room: state.room, selectedId: selectedTileId),
            ),
          );
        }
        return _DraggableMiniCall(
          room: state.room,
          selectedId: selectedTileId,
          onOpen: () => _onOpen?.call(context),
        );
      },
    );
  }

  static void _remove() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  static void dispose() {
    _remove();
    _subscription?.cancel();
    _subscription = null;
    PipService.isInPipMode.removeListener(_sync);
    _bloc = null;
    _overlay = null;
    _onOpen = null;
    selectedTileId = null;
    _screenVisible = false;
  }
}

class _DraggableMiniCall extends StatefulWidget {
  const _DraggableMiniCall({
    required this.room,
    required this.selectedId,
    required this.onOpen,
  });

  final lk.Room? room;
  final String? selectedId;
  final VoidCallback onOpen;

  @override
  State<_DraggableMiniCall> createState() => _DraggableMiniCallState();
}

class _DraggableMiniCallState extends State<_DraggableMiniCall> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) => Positioned(
    right: 16,
    bottom: 120,
    child: Transform.translate(
      offset: _offset,
      child: Container(
        width: 160,
        height: 112,
        decoration: BoxDecoration(
          color: const Color(0xFF252731),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x80000000), blurRadius: 18),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _CallPipTile(
                room: widget.room,
                selectedId: widget.selectedId,
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) =>
                    setState(() => _offset += details.delta),
                onTap: widget.onOpen,
              ),
            ),
            const Positioned(
              right: 7,
              top: 7,
              child: Icon(
                CupertinoIcons.arrow_up_left_arrow_down_right,
                color: CupertinoColors.white,
                size: 15,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.blurple, width: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CallPipTile extends StatelessWidget {
  const _CallPipTile({required this.room, required this.selectedId});

  final lk.Room? room;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final participants = <lk.Participant>[
      ...?room?.remoteParticipants.values,
      if (room?.localParticipant != null) room!.localParticipant!,
    ];
    if (participants.isEmpty) return const SizedBox.shrink();
    final selectedIdentity = selectedId?.split(':').first;
    final participant =
        participants
            .where((item) => item.identity == selectedIdentity)
            .firstOrNull ??
        participants.first;
    final source = selectedId?.endsWith(':screen') == true
        ? lk.TrackSource.screenShareVideo
        : lk.TrackSource.camera;
    final publication = participant.getTrackPublicationBySource(source);
    final track =
        publication?.muted == false && publication?.track is lk.VideoTrack
        ? publication!.track as lk.VideoTrack
        : null;
    Map<String, dynamic> metadata = {};
    try {
      final parsed = jsonDecode(participant.metadata ?? '{}');
      if (parsed is Map) metadata = Map<String, dynamic>.from(parsed);
    } catch (_) {}
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
    return Stack(
      fit: StackFit.expand,
      children: [
        if (track != null)
          lk.VideoTrackRenderer(
            track,
            fit: source == lk.TrackSource.screenShareVideo
                ? lk.VideoViewFit.contain
                : lk.VideoViewFit.cover,
          )
        else
          Center(child: BuildAvatar(url: avatar, wh: 64, size: 28)),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xCC000000)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 10,
          right: 10,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
