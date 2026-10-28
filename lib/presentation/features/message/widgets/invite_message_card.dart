import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/invite_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/calls/call_screen.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/message/widgets/invite_message_meta.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InviteMessageCard extends StatefulWidget {
  const InviteMessageCard({
    super.key,
    required this.invite,
    required this.code,
    this.onMention,
  });

  final InviteData invite;
  final String code;
  final ValueChanged<String>? onMention;

  @override
  State<InviteMessageCard> createState() => _InviteMessageCardState();
}

class _InviteMessageCardState extends State<InviteMessageCard> {
  bool _joining = false;
  bool _checking = false;
  InviteMembership? _membership;
  InvalidInviteReason? _invalidOverride;
  int _checkGeneration = 0;

  EntityType get _entityType =>
      widget.invite.entityType == EntityType.chat.value
      ? EntityType.chat
      : EntityType.server;

  bool get _isCallInvite => widget.invite.targetChatId != null;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<InviteRepository>()) _checkMembership();
  }

  @override
  void didUpdateWidget(covariant InviteMessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      _membership = null;
      _invalidOverride = null;
      if (sl.isRegistered<InviteRepository>()) _checkMembership();
    }
  }

  // В данных приглашения из сообщения ID сервера приходит как `id`.
  // Ответы API приглашений содержат `entityId` и собственный ID приглашения.
  int? get _entityId => widget.invite.entityId ?? widget.invite.id;

  Future<InviteMembership?> _checkMembership() async {
    if (!sl.isRegistered<InviteRepository>()) return null;
    final generation = ++_checkGeneration;
    final code = widget.code;
    setState(() => _checking = true);
    final result = await sl<InviteRepository>().checkMembership(code);
    if (!mounted || generation != _checkGeneration || code != widget.code) {
      return null;
    }
    setState(() => _checking = false);
    return result.fold((_) => null, (membership) {
      setState(() => _membership = membership);
      return membership;
    });
  }

  InvalidInviteReason? get _invalidReason =>
      _invalidOverride ?? invalidInviteReason(widget.invite, DateTime.now());

  Future<void> _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      final membership = await _checkMembership();
      if (!mounted) return;
      if (sl.isRegistered<InviteRepository>() && membership == null) {
        CustomToast.open(
          context: context,
          message: 'Не удалось проверить приглашение',
        );
        return;
      }
      if (membership?.isMember == true ||
          (membership == null && _isMemberLocally())) {
        await _openDestination(
          membership?.entityId ?? _entityId,
          membership?.entityType ?? _entityType,
          membership?.targetChatId ?? widget.invite.targetChatId,
        );
        return;
      }
      final invitesBloc = context.read<InvitesBloc>();
      if (invitesBloc.state.isPending(InviteOperation.accept)) return;
      invitesBloc.add(AcceptInvite(widget.code));
      final result = await invitesBloc.stream.firstWhere(
        (state) =>
            state.lastCompleted == InviteOperation.accept ||
            state.failureFor(InviteOperation.accept) != null,
      );
      if (!mounted) return;
      final failure = result.failureFor(InviteOperation.accept);
      if (failure != null) {
        final reason = _reasonFromError(failure.message);
        if (reason != null) {
          setState(() => _invalidOverride = reason);
        } else {
          CustomToast.open(context: context, message: failure.message);
        }
        return;
      }
      final acceptance = result.acceptance;
      final server = acceptance?.server;
      if (server != null) {
        context.read<ServersBloc>().add(ServerUpserted(server.toMap()));
      }
      final conversation = acceptance?.conversation;
      if (conversation != null) {
        context.read<ChatBloc>().add(AddChat(conversation));
      }
      _membership = InviteMembership(
        isMember: true,
        entityId: acceptance?.entityId ?? _entityId ?? 0,
        entityType: acceptance?.entityType ?? _entityType,
        targetChatId: acceptance?.targetChatId ?? widget.invite.targetChatId,
      );
      await _openDestination(
        _membership!.entityId,
        _membership!.entityType,
        _membership!.targetChatId,
        acceptedChat: conversation ?? acceptance?.chat,
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  InvalidInviteReason? _reasonFromError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('revok') || lower.contains('отозван')) {
      return InvalidInviteReason.revoked;
    }
    if (lower.contains('limit') ||
        lower.contains('max') ||
        lower.contains('использован')) {
      return InvalidInviteReason.maxed;
    }
    if (lower.contains('expir') ||
        lower.contains('ист') ||
        lower.contains('недействител')) {
      return InvalidInviteReason.expired;
    }
    return null;
  }

  bool _isMemberLocally() {
    final id = _entityId;
    if (id == null) return false;
    if (_entityType == EntityType.server &&
        context.read<ServersBloc>().state is ServersLoaded) {
      return (context.read<ServersBloc>().state as ServersLoaded).servers.any(
        (server) => server.id == id,
      );
    }
    return _entityType == EntityType.chat &&
        sl.isRegistered<ChatRepository>() &&
        sl<ChatRepository>().getCached().any((chat) => chat.id == id);
  }

  Future<void> _openDestination(
    int? entityId,
    EntityType entityType,
    int? targetChatId, {
    Chat? acceptedChat,
  }) async {
    if (entityId == null || !mounted) return;
    if (entityType == EntityType.server) {
      if (sl.isRegistered<ServerRepository>() &&
          sl<ServerRepository>().getByIdCached(entityId) == null) {
        context.read<ServersBloc>().add(const GetServers());
      }
      context.read<ServersBloc>().add(SelectServer(entityId));
      if (targetChatId == null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
    }
    if (targetChatId != null) {
      await CallScreen.open(
        context,
        chatId: targetChatId,
        entityKey: EntityKey(entityId: entityId, entityType: entityType),
        title: widget.invite.targetChatName ?? widget.invite.name ?? 'Звонок',
        announceCall: false,
      );
      return;
    }
    final cached = sl.isRegistered<ChatRepository>()
        ? sl<ChatRepository>().getCached().where((chat) => chat.id == entityId)
        : <Chat>[];
    final chat =
        acceptedChat ??
        (cached.isEmpty ? null : cached.first) ??
        Chat(
          id: entityId,
          name: widget.invite.name ?? 'Группа',
          type: ChatType.group,
        );
    await ChatScreen.open(context, chat, false);
  }

  void _mention() {
    final displayName = widget.invite.user?.displayName ?? 'автора приглашения';
    final destination = _entityType == EntityType.chat
        ? 'в группу'
        : 'на сервер';
    final name = widget.invite.name ?? 'чат';
    widget.onMention?.call(
      '@$displayName, не могли бы вы отправить новое приглашение $destination $name? Ссылка недействительна.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final invalidReason = _invalidReason;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mainBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.65)),
      ),
      child: invalidReason == null ? _validCard() : _invalidCard(invalidReason),
    );
  }

  Widget _validCard() {
    final entityId = _entityId;
    final isChat = _entityType == EntityType.chat;
    final name = widget.invite.name?.isNotEmpty == true
        ? widget.invite.name!
        : isChat
        ? 'Неизвестная группа'
        : 'Неизвестный сервер';
    final displayName =
        _isCallInvite && widget.invite.targetChatName?.isNotEmpty == true
        ? '$name · ${widget.invite.targetChatName}'
        : name;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.highTextStyle.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.invite.memberCount != null ||
            widget.invite.onlineMemberCount != null)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _count(
                CupertinoColors.activeGreen,
                '${widget.invite.onlineMemberCount ?? 0} в сети',
              ),
              _count(
                AppColors.greyple,
                '${widget.invite.memberCount ?? 0} участников',
              ),
            ],
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: isChat
              ? _actionButton(_isMemberLocally())
              : BlocBuilder<ServersBloc, ServersState>(
                  builder: (context, state) => _actionButton(
                    entityId != null &&
                        state is ServersLoaded &&
                        state.servers.any((server) => server.id == entityId),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _actionButton(bool localMember) {
    final isMember = _membership?.isMember ?? localMember;
    final label = isMember
        ? _isCallInvite
              ? 'Перейти в звонок'
              : _entityType == EntityType.chat
              ? 'Перейти в группу'
              : 'Перейти на сервер'
        : 'Присоединиться';
    return CupertinoButton.filled(
      key: const ValueKey('invite_card_action'),
      padding: const EdgeInsets.symmetric(vertical: 9),
      onPressed: _joining || _checking ? null : _join,
      child: _joining || _checking
          ? const CupertinoActivityIndicator()
          : Text(label),
    );
  }

  Widget _avatar() {
    final name = widget.invite.name ?? '';
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final path = widget.invite.pathAvatar;
    String? url;
    if (path != null && path.isNotEmpty) {
      final transformed = Domain.transformUrl(path);
      final uri = Uri.tryParse(transformed);
      if (uri != null) {
        url = uri.hasScheme
            ? transformed
            : Uri.parse(Domain.imageDomain).resolve(transformed).toString();
      }
    }
    Widget fallback() => Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      color: AppColors.blurple,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.onBlurple,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url == null
          ? fallback()
          : CachedNetworkImage(
              imageUrl: url,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              placeholder: (_, _) => fallback(),
              errorWidget: (_, _, _) => fallback(),
            ),
    );
  }

  Widget _count(Color dotColor, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
      ),
    ],
  );

  Widget _invalidCard(InvalidInviteReason reason) {
    final subtitle = switch (reason) {
      InvalidInviteReason.revoked =>
        'Это приглашение было отозвано владельцем сервера.',
      InvalidInviteReason.maxed =>
        'Это приглашение достигло максимального числа использований.',
      InvalidInviteReason.expired =>
        'Срок действия ссылки истёк или она недействительна.',
    };
    final displayName = widget.invite.user?.displayName ?? 'автора приглашения';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Вы получили приглашение, но…',
          style: AppText.mediumTextStyle.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: AppColors.errorRed,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subtitle,
                style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Попросите новое приглашение у $displayName?',
          style: AppText.lowTextStyle.copyWith(color: AppColors.white),
        ),
        if (widget.onMention != null) ...[
          const SizedBox(height: 10),
          CupertinoButton(
            key: const ValueKey('invite_card_mention'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: AppColors.actionGrey,
            onPressed: _mention,
            child: const Text('Упомянуть'),
          ),
        ],
      ],
    );
  }
}
