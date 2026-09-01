enum ChatType {
  personal("personal"),
  solo("solo"),
  group("group"),
  channel("channel");

  final String value;

  const ChatType(this.value);

  static ChatType fromString(String? value) {
    return ChatType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChatType.personal,
    );
  }
}
