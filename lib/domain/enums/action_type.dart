enum ActionType {
  create("Create"),
  read("Read"),
  update("Update"),
  delete("Delete");

  final String value;

  const ActionType(this.value);

  static ActionType fromString(String? value) {
    return ActionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActionType.read,
    );
  }
}
