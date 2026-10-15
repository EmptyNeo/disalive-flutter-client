import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

String formatInviteExpiration(String? value) {
  if (value == null || value.trim().isEmpty || value == '0') return 'никогда';
  final timestamp = int.tryParse(value);
  final date = timestamp == null
      ? DateTime.tryParse(value)
      : DateTime.fromMillisecondsSinceEpoch(
          timestamp > 1000000000000 ? timestamp : timestamp * 1000,
        );
  if (date == null) return value;
  return DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal());
}

class ServerInviteItem extends StatelessWidget {
  const ServerInviteItem({
    super.key,
    required this.invite,
    required this.onCopy,
    required this.onRevoke,
    this.isRevoking = false,
  });

  final InviteData invite;
  final VoidCallback onCopy;
  final VoidCallback onRevoke;
  final bool isRevoking;

  @override
  Widget build(BuildContext context) {
    final user = invite.user;
    final usageLimit = invite.maxInvite ?? 0;
    final usage =
        '${invite.currentCountInvite ?? 0}/${usageLimit <= 0 ? '∞' : usageLimit}';
    final revoked = invite.isRevoked;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BuildAvatar(url: user?.urlAvatar, wh: 36, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.getDisplayName ?? 'Неизвестный пользователь',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user?.username == null ? '—' : '@${user!.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.greyple, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (revoked)
                Text(
                  'Отозвано',
                  style: TextStyle(color: AppColors.greyple, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Код: ${invite.code ?? '—'}',
            style: TextStyle(color: AppColors.white, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Использований: $usage',
            style: TextStyle(color: AppColors.greyple, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            'Истекает: ${formatInviteExpiration(invite.expiresAt)}',
            style: TextStyle(color: AppColors.greyple, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  key: ValueKey('copy_invite_${invite.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: AppColors.actionGrey,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: revoked || invite.inviteUrl == null
                      ? null
                      : onCopy,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.doc_on_doc, size: 16),
                      SizedBox(width: 7),
                      Text('Копировать', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                key: ValueKey('revoke_invite_${invite.id}'),
                padding: const EdgeInsets.all(7),
                minimumSize: const Size(36, 36),
                onPressed: revoked || invite.id == null || isRevoking
                    ? null
                    : onRevoke,
                child: isRevoking
                    ? const CupertinoActivityIndicator()
                    : Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: revoked ? AppColors.greyple : AppColors.errorRed,
                        size: 24,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
