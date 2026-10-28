/// Права доступа для чата (личного или группового).
abstract final class ChatPermissions {
  static const String manageChat = 'manageChat';
  static const String manageInvites = 'manageInvites';
  static const String manageMessages = 'manageMessages';
  static const String manageMembers = 'manageMembers';
  static const String manageRoles = 'manageRoles';
  static const String manageCalls = 'manageCalls';
}

/// Права доступа для сервера.
abstract final class ServerPermissions extends GeneralPermissions {
  static const String manageServer = 'manageServer';
  static const String manageChannels = 'manageChannels';
  static const String manageCategories = 'manageCategories';
  static const String manageInvites = 'manageInvites';
  static const String manageMessages = 'manageMessages';
  static const String manageMembers = 'manageMembers';
  static const String manageRoles = 'manageRoles';
  static const String manageCalls = 'manageCalls';
}

/// Общие права доступа, которые могут применяться как к чату, так и к серверу.
/// Удобно использовать в универсальных компонентах, где контекст сущности не важен.
abstract final class GeneralPermissions {
  static const String manageInvites = 'manageInvites';
  static const String manageMessages = 'manageMessages';
  static const String manageMembers = 'manageMembers';
  static const String manageRoles = 'manageRoles';
  static const String manageCalls = 'manageCalls';
}
