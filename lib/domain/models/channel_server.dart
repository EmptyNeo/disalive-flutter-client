import 'package:equatable/equatable.dart';
import 'package:disalive/domain/models/member.dart';

class ChannelServer extends Equatable {
  final int? id;
  final int? serverId;
  final int? chatId;
  final String? type;
  final int? categoryId;
  final bool isPrivate;
  final int? maxParticipants;
  final int slowModeSeconds;
  final int sortOrder;
  final String? slowModeLastSentAt;
  final String? chatName;
  final int newMessagesCount;
  final int? lastIdReadMessage;
  final List<Member> members;
  final List<int> allowedUsers;
  final List<int> allowedRoles;

  const ChannelServer({
    this.id,
    this.serverId,
    this.chatId,
    this.type,
    this.categoryId,
    this.isPrivate = false,
    this.maxParticipants,
    this.slowModeSeconds = 0,
    this.sortOrder = 0,
    this.slowModeLastSentAt,
    this.chatName,
    this.newMessagesCount = 0,
    this.lastIdReadMessage,
    this.members = const [],
    this.allowedUsers = const [],
    this.allowedRoles = const [],
  });

  factory ChannelServer.fromMap(Map<String, dynamic> map) => ChannelServer(
    id: (map['id'] as num?)?.toInt(),
    serverId: (map['serverId'] as num?)?.toInt(),
    chatId: (map['chatId'] as num?)?.toInt(),
    type: map['type'] as String?,
    categoryId: (map['categoryId'] as num?)?.toInt(),
    isPrivate: map['isPrivate'] == true || map['isPrivate'] == 1,
    maxParticipants: (map['maxParticipants'] as num?)?.toInt(),
    slowModeSeconds: (map['slowModeSeconds'] as num?)?.toInt() ?? 0,
    sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    slowModeLastSentAt: map['slowModeLastSentAt'] as String?,
    chatName: map['chatName'] as String?,
    newMessagesCount: (map['newMessagesCount'] as num?)?.toInt() ?? 0,
    lastIdReadMessage: (map['lastIdReadMessage'] as num?)?.toInt(),
    members: (map['members'] as List? ?? const [])
        .whereType<Map>()
        .map((member) => Member.fromMap(Map<String, dynamic>.from(member)))
        .toList(),
    allowedUsers: (map['allowedUsers'] as List? ?? const [])
        .map((value) => (value as num).toInt())
        .toList(),
    allowedRoles: (map['allowedRoles'] as List? ?? const [])
        .map((value) => (value as num).toInt())
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'serverId': serverId,
    'chatId': chatId,
    'type': type,
    'categoryId': categoryId,
    'isPrivate': isPrivate,
    'maxParticipants': maxParticipants,
    'slowModeSeconds': slowModeSeconds,
    'sortOrder': sortOrder,
    'slowModeLastSentAt': slowModeLastSentAt,
    'chatName': chatName,
    'newMessagesCount': newMessagesCount,
    'lastIdReadMessage': lastIdReadMessage,
    'members': members
        .map(
          (member) => {
            'userId': member.fkUser,
            'lastIdReadMessage': member.lastIdReadMessage,
            if (member.isSelf != null) 'isSelf': member.isSelf,
          },
        )
        .toList(),
    'allowedUsers': allowedUsers,
    'allowedRoles': allowedRoles,
  };

  ChannelServer copyWith({String? slowModeLastSentAt, List<Member>? members}) =>
      ChannelServer(
        id: id,
        serverId: serverId,
        chatId: chatId,
        type: type,
        categoryId: categoryId,
        isPrivate: isPrivate,
        maxParticipants: maxParticipants,
        slowModeSeconds: slowModeSeconds,
        sortOrder: sortOrder,
        slowModeLastSentAt: slowModeLastSentAt ?? this.slowModeLastSentAt,
        chatName: chatName,
        newMessagesCount: newMessagesCount,
        lastIdReadMessage: lastIdReadMessage,
        members: members ?? this.members,
        allowedUsers: allowedUsers,
        allowedRoles: allowedRoles,
      );

  @override
  List<Object?> get props => [
    id,
    serverId,
    chatId,
    type,
    categoryId,
    isPrivate,
    maxParticipants,
    slowModeSeconds,
    sortOrder,
    slowModeLastSentAt,
    chatName,
    newMessagesCount,
    lastIdReadMessage,
    members,
    allowedUsers,
    allowedRoles,
  ];
}
