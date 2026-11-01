import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/responses/reaction_summary_page.dart';
import 'package:disalive/domain/models/responses/reaction_users_page.dart';

abstract class ReactionsRepository {
  Future<Either<Failure, bool>> toggleReaction({
    required int chatId,
    required int entityId,
    required EntityType entityType,
    required int messageId,
    required String nameReaction,
  });

  Future<Either<Failure, ReactionSummaryPage>> getByMessage({
    required int messageId,
    required int entityId,
    required EntityType entityType,
    int cursor = 0,
    int limit = 30,
  });

  Future<Either<Failure, ReactionUsersPage>> getUsersByMessage({
    required int messageId,
    required int entityId,
    required EntityType entityType,
    required String nameReaction,
    int cursor = 0,
    int limit = 30,
  });
}
