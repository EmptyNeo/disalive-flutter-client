// lib/domain/models/friend_request.dart
import 'package:disalive/domain/enums/request_type.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:equatable/equatable.dart';

class FriendRequest extends Equatable {
  final int? id;
  final int? senderId;
  final int? receiverId;
  final RequestType? type;
  final UserModel? user;

  const FriendRequest({
    this.id,
    this.senderId,
    this.receiverId,
    this.type,
    this.user,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      type: map['type'] != null
          ? RequestType.fromString(map['type'] as String)
          : null,
      user: map['user'] != null
          ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (senderId != null) 'senderId': senderId,
      if (receiverId != null) 'receiverId': receiverId,
      if (type != null) 'type': type?.value,
      if (user != null) 'user': user?.toMap(),
    };
  }

  FriendRequest copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    RequestType? type,
    UserModel? user,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      user: user ?? this.user,
    );
  }

  bool get isIncoming => type == RequestType.incoming;

  bool get isOutgoing => type == RequestType.outgoing;

  @override
  List<Object?> get props => [id, senderId, receiverId, type, user];
}
