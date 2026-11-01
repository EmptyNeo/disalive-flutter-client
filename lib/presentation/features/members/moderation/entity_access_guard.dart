import 'package:disalive/app/di/di.dart';
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
  await showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text('Доступ ограничен'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_banMessage(entityKey.entityType, access)),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Понятно'),
        ),
      ],
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
