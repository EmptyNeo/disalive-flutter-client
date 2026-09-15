enum ActionSessionType {
  target('target'),
  others('others');

  final String value;

  const ActionSessionType(this.value);

  static ActionSessionType? fromString(String? value) {
    if (value == null) return null;
    for (final type in ActionSessionType.values) {
      if (type.value.toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    return null;
  }
}
