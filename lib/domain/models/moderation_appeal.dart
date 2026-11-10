import 'package:disalive/domain/enums/appeal_target_type.dart';

class AppealTarget {
  const AppealTarget({
    required this.type,
    required this.id,
    required this.name,
  });

  final AppealTargetType type;
  final int id;
  final String name;

  factory AppealTarget.fromMap(Map<String, dynamic> map) => AppealTarget(
    type: AppealTargetType.fromValue(map['type'] as String?)!,
    id: (map['id'] as num).toInt(),
    name: map['name'] as String? ?? '',
  );
}

class ModerationAppeal {
  const ModerationAppeal({
    required this.id,
    required this.type,
    required this.targetId,
    required this.status,
    this.reason = '',
    this.createdAt,
    this.reviewerNote,
  });

  final int id;
  final AppealTargetType type;
  final int targetId;
  final String status;
  final String reason;
  final String? createdAt;
  final String? reviewerNote;

  bool get isPending => status == 'pending';

  factory ModerationAppeal.fromMap(Map<String, dynamic> map) =>
      ModerationAppeal(
        id: (map['id'] as num).toInt(),
        type: AppealTargetType.fromValue(map['targetType'] as String?)!,
        targetId: (map['targetId'] as num).toInt(),
        status: map['status'] as String? ?? '',
        reason: map['reason'] as String? ?? '',
        createdAt: map['createdAt'] as String?,
        reviewerNote: map['reviewerNote'] as String?,
      );
}
