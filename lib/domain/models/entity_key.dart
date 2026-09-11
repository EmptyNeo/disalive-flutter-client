import 'package:disalive/domain/enums/entity_type.dart';

class EntityKey {
  final int entityId;
  final EntityType entityType;

  const EntityKey({required this.entityId, required this.entityType});

  @override
  bool operator ==(Object other) =>
      other is EntityKey &&
      other.entityId == entityId &&
      other.entityType == entityType;

  @override
  int get hashCode => Object.hash(entityId, entityType);
}
