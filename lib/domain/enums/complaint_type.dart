enum ComplaintType {
  user('user', 'Пользователь', 'пользователя', 'target_user'),
  server('server', 'Сервер', 'сервер', 'target_server'),
  group('group', 'Группа', 'группу', 'target_group'),
  message('message', 'Сообщение', 'сообщение', 'target_message'),
  channel('channel', 'Канал', 'канал', 'target_channel');

  const ComplaintType(
    this.value,
    this.displayName,
    this.accusativeName,
    this.targetField,
  );

  final String value;
  final String displayName;
  final String accusativeName;
  final String targetField;
}
