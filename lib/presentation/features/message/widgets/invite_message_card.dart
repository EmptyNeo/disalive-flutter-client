import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/models/invite_data.dart';
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
  InvalidInviteReason? _invalidOverride;

  // В данных приглашения из сообщения ID сервера приходит как `id`.
  // Ответы API приглашений содержат `entityId` и собственный ID приглашения.
  int? get _serverId => widget.invite.entityId ?? widget.invite.id;

  InvalidInviteReason? get _invalidReason =>
      _invalidOverride ?? invalidInviteReason(widget.invite, DateTime.now());

  Future<void> _join() async {
    if (_joining) return;
    final invitesBloc = context.read<InvitesBloc>();
    if (invitesBloc.state.isPending(InviteOperation.accept)) return;
    setState(() => _joining = true);
    invitesBloc.add(AcceptInvite(widget.code));
    try {
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
      final server = result.acceptance?.server;
      final serverId = server?.id ?? _serverId;
      if (server != null) {
        context.read<ServersBloc>().add(ServerUpserted(server.toMap()));
      }
      if (serverId != null) {
        _openServer(serverId);
      }
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

  void _openServer(int serverId) {
    context.read<ServersBloc>().add(SelectServer(serverId));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _mention() {
    final displayName = widget.invite.user?.displayName ?? 'автора приглашения';
    final serverName = widget.invite.name ?? 'сервер';
    widget.onMention?.call(
      '@$displayName, не могли бы вы отправить новое приглашение на сервер $serverName? Ссылка недействительна.',
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
    final serverId = _serverId;
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
                widget.invite.name?.isNotEmpty == true
                    ? widget.invite.name!
                    : 'Неизвестный сервер',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.highTextStyle.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
          child: BlocBuilder<ServersBloc, ServersState>(
            builder: (context, state) {
              final hasServer =
                  serverId != null &&
                  state is ServersLoaded &&
                  state.servers.any((server) => server.id == serverId);
              return CupertinoButton.filled(
                key: const ValueKey('invite_card_action'),
                padding: const EdgeInsets.symmetric(vertical: 9),
                onPressed: _joining
                    ? null
                    : hasServer
                    ? () => _openServer(serverId)
                    : _join,
                child: _joining
                    ? const CupertinoActivityIndicator()
                    : Text(hasServer ? 'Перейти на сервер' : 'Присоединиться'),
              );
            },
          ),
        ),
      ],
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
