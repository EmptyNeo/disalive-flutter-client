import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_access.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';

Future<EntityAccess?> checkEntityAccess(
  BuildContext context,
  EntityKey entityKey,
) async {
  final result = await sl<MembersRepository>().checkAccess(entityKey);
  if (!context.mounted) return null;

  final access = result.fold<EntityAccess?>((failure) {
    CustomToast.open(context: context, message: failure.message);
    return null;
  }, (access) => access);
  if (access == null || !access.banned) return access;

  await showEntityBanNotice(context, entityKey: entityKey, access: access);
  return null;
}

Future<void> showEntityBanNotice(
  BuildContext context, {
  required EntityKey entityKey,
  required EntityAccess access,
}) async {
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть уведомление',
    barrierColor: CupertinoColors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    pageBuilder: (dialogContext, _, _) => SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.mainBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CupertinoIcons.exclamationmark_shield,
                        size: 26,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Доступ ограничен',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _banMessage(entityKey.entityType, access),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.greyple, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton(
                    color: AppColors.blurple,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Понятно'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _banMessage(EntityType entityType, EntityAccess access) {
  final destination = entityType == EntityType.server
      ? 'на сервере'
      : 'в группе';
  final reason = access.banReason?.trim();
  final expiry = _formatExpiry(access.banExpiresAt);
  return [
    'Вы заблокированы $destination.',
    if (reason != null && reason.isNotEmpty) 'Причина: $reason.',
    if (reason == null || reason.isEmpty) 'Причина не указана.',
    expiry == null ? 'Срок: бессрочно.' : 'Доступ закрыт до $expiry.',
  ].join('\n');
}

String? _formatExpiry(String? value) {
  if (value == null || value.isEmpty) return null;
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
      '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}
