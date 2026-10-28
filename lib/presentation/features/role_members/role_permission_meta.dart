import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/permissions.dart';

class RolePermissionMeta {
  const RolePermissionMeta(this.key, this.label, this.description);
  final String key;
  final String label;
  final String description;
}

List<RolePermissionMeta> rolePermissionsFor(EntityType type) => [
  const RolePermissionMeta(
    'administrator',
    'Администратор',
    'Дает все права и обходит любые ограничения.',
  ),
  if (type == EntityType.chat)
    const RolePermissionMeta(
      ChatPermissions.manageChat,
      'Управление чатом',
      'Позволяет редактировать чат',
    ),
  if (type == EntityType.chat)
    const RolePermissionMeta(
      ChatPermissions.manageInvites,
      'Управление приглашениями',
      'Создание и отзыв приглашений',
    ),
  if (type == EntityType.server) ...[
    const RolePermissionMeta(
      ServerPermissions.manageServer,
      'Управление сервером',
      'Редактирование настроек сервера',
    ),
    const RolePermissionMeta(
      ServerPermissions.manageChannels,
      'Управление каналами',
      'Создание, редактирование и удаление каналов',
    ),
    const RolePermissionMeta(
      ServerPermissions.manageCategories,
      'Управление категориями',
      'Создание, редактирование и удаление категорий',
    ),
    const RolePermissionMeta(
      ServerPermissions.manageInvites,
      'Управление приглашениями',
      'Создание и отзыв приглашений',
    ),
  ],
  const RolePermissionMeta(
    GeneralPermissions.manageMessages,
    'Управление сообщениями',
    'Удаление сообщений других участников',
  ),
  const RolePermissionMeta(
    GeneralPermissions.manageMembers,
    'Управление участниками',
    'Добавление и исключение участников',
  ),
  const RolePermissionMeta(
    GeneralPermissions.manageRoles,
    'Управление ролями',
    'Создание, редактирование и удаление ролей',
  ),
  const RolePermissionMeta(
    GeneralPermissions.manageCalls,
    'Управление звонками',
    'Заглушение и исключение участников из звонка',
  ),
];

Map<String, bool> normalizeRolePermissions(
  EntityType type,
  Map<String, bool> permissions,
) {
  final result = Map<String, bool>.from(permissions);
  final keys = rolePermissionsFor(type).map((meta) => meta.key);
  for (final key in keys) {
    result.putIfAbsent(key, () => false);
  }
  final otherKeys = keys.where((key) => key != 'administrator');
  if (result['administrator'] == true ||
      otherKeys.every((key) => result[key] == true)) {
    for (final key in keys) {
      result[key] = true;
    }
  }
  return result;
}

Map<String, bool> changeRolePermission(
  EntityType type,
  Map<String, bool> permissions,
  String key,
  bool value,
) {
  final result = Map<String, bool>.from(permissions);
  final otherKeys = rolePermissionsFor(type)
      .map((meta) => meta.key)
      .where((permission) => permission != 'administrator');
  if (key == 'administrator') {
    result['administrator'] = value;
    for (final permission in otherKeys) {
      result[permission] = value;
    }
  } else {
    result[key] = value;
    result['administrator'] = otherKeys.every(
      (permission) => result[permission] == true,
    );
  }
  return result;
}
