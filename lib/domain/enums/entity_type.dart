enum EntityType {
  chat('chat'),
  server('server');

  final String value;

  const EntityType(this.value);

  static EntityType fromString(String? value) {
    return EntityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EntityType.chat,
    );
  }
}
