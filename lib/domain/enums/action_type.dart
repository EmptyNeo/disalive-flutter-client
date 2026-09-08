enum ActionType {
  create('Create'),
  update('Update'),
  delete('Delete'),
  block('UpdateBlockStatus');

  final String value;

  const ActionType(this.value);

  static ActionType? fromString(String? value) {
    if (value == null) return null;
    for (final type in ActionType.values) {
      if (type.value.toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    return null;
  }
}
