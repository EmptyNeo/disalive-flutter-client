enum AppealTargetType {
  user('user', 'Учётная запись'),
  server('server', 'Сервер'),
  group('group', 'Группа');

  const AppealTargetType(this.value, this.displayName);

  final String value;
  final String displayName;

  static AppealTargetType? fromValue(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
