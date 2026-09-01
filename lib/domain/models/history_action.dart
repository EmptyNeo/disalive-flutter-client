// lib/domain/models/history_action.dart
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/entity_action_type.dart';
import 'package:disalive/domain/models/user.dart';

class HistoryAction extends Equatable {
  final int? id;
  final int? userId;
  final int? interactionUserId;
  final int? entityId;
  final EntityType? entityType;
  final EntityActionType? entityActionType;
  final int? lastIdMessage;
  final String? startDate;
  final String? endDate;
  final int? startTimestamp;
  final String? durationFormatted;
  final String? startTimeFormatted;
  final bool? isActive;
  final UserModel? initiatorUser;
  final UserModel? interactionUser;

  const HistoryAction({
    this.id,
    this.userId,
    this.interactionUserId,
    this.entityId,
    this.entityType,
    this.entityActionType,
    this.lastIdMessage,
    this.startDate,
    this.endDate,
    this.startTimestamp,
    this.durationFormatted,
    this.startTimeFormatted,
    this.isActive,
    this.initiatorUser,
    this.interactionUser,
  });

  factory HistoryAction.fromMap(Map<String, dynamic> map) {
    return HistoryAction(
      id: map['id'],
      userId: map['userId'],
      interactionUserId: map['interactionUserId'],
      entityId: map['entityId'],
      entityType: map['entityType'] != null
          ? EntityType.fromString(map['entityType'] as String)
          : null,
      entityActionType: map['entityActionType'] != null
          ? EntityActionType.fromString(map['entityActionType'] as String)
          : null,
      lastIdMessage: map['lastIdMessage'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      startTimestamp: map['startTimestamp'],
      durationFormatted: map['durationFormatted'],
      startTimeFormatted: map['startTimeFormatted'],
      isActive: map['isActive'],
      initiatorUser: map['initiatorUser'] != null
          ? UserModel.fromMap(map['initiatorUser'] as Map<String, dynamic>)
          : null,
      interactionUser: map['interactionUser'] != null
          ? UserModel.fromMap(map['interactionUser'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      if (interactionUserId != null) 'interactionUserId': interactionUserId,
      if (entityId != null) 'entityId': entityId,
      if (entityType != null) 'entityType': entityType?.value,
      if (entityActionType != null) 'entityActionType': entityActionType?.value,
      if (lastIdMessage != null) 'lastIdMessage': lastIdMessage,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (startTimestamp != null) 'startTimestamp': startTimestamp,
      if (durationFormatted != null) 'durationFormatted': durationFormatted,
      if (startTimeFormatted != null) 'startTimeFormatted': startTimeFormatted,
      if (isActive != null) 'isActive': isActive,
      if (initiatorUser != null) 'initiatorUser': initiatorUser?.toMap(),
      if (interactionUser != null) 'interactionUser': interactionUser?.toMap(),
    };
  }

  HistoryAction copyWith({
    int? id,
    int? userId,
    int? interactionUserId,
    int? entityId,
    EntityType? entityType,
    EntityActionType? entityActionType,
    int? lastIdMessage,
    String? startDate,
    String? endDate,
    int? startTimestamp,
    String? durationFormatted,
    String? startTimeFormatted,
    bool? isActive,
    UserModel? initiatorUser,
    UserModel? interactionUser,
  }) {
    return HistoryAction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      interactionUserId: interactionUserId ?? this.interactionUserId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      entityActionType: entityActionType ?? this.entityActionType,
      lastIdMessage: lastIdMessage ?? this.lastIdMessage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      durationFormatted: durationFormatted ?? this.durationFormatted,
      startTimeFormatted: startTimeFormatted ?? this.startTimeFormatted,
      isActive: isActive ?? this.isActive,
      initiatorUser: initiatorUser ?? this.initiatorUser,
      interactionUser: interactionUser ?? this.interactionUser,
    );
  }

  bool get isActionActive => isActive ?? (endDate == null);

  @override
  List<Object?> get props => [
    id,
    userId,
    interactionUserId,
    entityId,
    entityType,
    entityActionType,
    lastIdMessage,
    startDate,
    endDate,
    startTimestamp,
    durationFormatted,
    startTimeFormatted,
    isActive,
    initiatorUser,
    interactionUser,
  ];
}