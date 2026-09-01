// lib/domain/enums/entity_action_type.dart
enum EntityActionType {
  called("Called"),
  added("Added"),
  joined("Joined"),
  lefted("Lefted"),
  cameout("Cameout"),
  excluded("Excluded");

  final String value;
  const EntityActionType(this.value);

  static EntityActionType fromString(String? value) {
    return EntityActionType.values.firstWhere(
          (type) => type.value == value,
      orElse: () => EntityActionType.called,
    );
  }
}