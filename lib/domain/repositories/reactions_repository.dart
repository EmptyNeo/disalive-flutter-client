import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';

abstract class ReactionsRepository {
  Future<Either<Failure, bool>> toggleReaction({
    required int chatId,
    required int entityId,
    required EntityType entityType,
    required int messageId,
    required String nameReaction,
  });
}
