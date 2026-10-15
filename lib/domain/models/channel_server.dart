import 'package:equatable/equatable.dart';

class ChannelServer extends Equatable {
  final int? id;
  final int? serverId;
  final int? chatId;
  final String? type;
  final int? categoryId;
  final bool isPrivate;
  final String? chatName;
  final int newMessagesCount;
  final int? lastIdReadMessage;
  final List<int> allowedUsers;
  final List<int> allowedRoles;

  const ChannelServer({
    this.id,
    this.serverId,
    this.chatId,
    this.type,
    this.categoryId,
    this.isPrivate = false,
    this.chatName,
    this.newMessagesCount = 0,
    this.lastIdReadMessage,
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
    chatName: map['chatName'] as String?,
    newMessagesCount: (map['newMessagesCount'] as num?)?.toInt() ?? 0,
    lastIdReadMessage: (map['lastIdReadMessage'] as num?)?.toInt(),
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
    'chatName': chatName,
    'newMessagesCount': newMessagesCount,
    'lastIdReadMessage': lastIdReadMessage,
    'allowedUsers': allowedUsers,
    'allowedRoles': allowedRoles,
  };

  @override
  List<Object?> get props => [
    id,
    serverId,
    chatId,
    type,
    categoryId,
    isPrivate,
    chatName,
    newMessagesCount,
    lastIdReadMessage,
    allowedUsers,
    allowedRoles,
  ];
}
