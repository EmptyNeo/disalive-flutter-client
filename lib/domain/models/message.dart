// lib/domain/models/message.dart
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/models/link_preview.dart';
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/reaction_message.dart';

class Message extends Equatable {
  final int? id;
  final int? chatId;
  final int? userId;
  final String? text;
  final String? time;
  final LinkPreview? linkPreview;
  final InviteData? inviteData;
  final UserModel? user;
  final List<FileMessage>? attachments;
  final List<ReactionMessage>? reactions;
  final Message? answerMessage;
  final Message? forwardMessage;
  final int? answerMessageId;
  final int? forwardMessageId;

  const Message({
    this.id,
    this.chatId,
    this.userId,
    this.text,
    this.time,
    this.linkPreview,
    this.inviteData,
    this.user,
    this.attachments,
    this.reactions,
    this.answerMessage,
    this.forwardMessage,
    this.answerMessageId,
    this.forwardMessageId,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      chatId: map['chatId'],
      userId: map['userId'],
      text: map['text'],
      time: map['time'],
      linkPreview: map['linkPreview'] != null
          ? LinkPreview.fromMap(map['linkPreview'] as Map<String, dynamic>)
          : null,
      inviteData: map['inviteData'] != null
          ? InviteData.fromMap(map['inviteData'] as Map<String, dynamic>)
          : null,
      user: map['user'] != null
          ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
          : null,
      attachments: map['attachments'] != null
          ? (map['attachments'] as List)
                .map((e) => FileMessage.fromMap(e as Map<String, dynamic>))
                .toList()
          : null,
      reactions: map['reactions'] != null
          ? (map['reactions'] as List)
                .map((e) => ReactionMessage.fromMap(e as Map<String, dynamic>))
                .toList()
          : null,
      answerMessage: map['answerMessage'] != null
          ? Message.fromMap(map['answerMessage'] as Map<String, dynamic>)
          : null,
      forwardMessage: map['forwardMessage'] != null
          ? Message.fromMap(map['forwardMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (chatId != null) 'chatId': chatId,
      if (userId != null) 'userId': userId,
      if (text != null) 'text': text,
      if (time != null) 'time': time,
      if (linkPreview != null) 'linkPreview': linkPreview,
      if (inviteData != null) 'inviteData': inviteData,
      if (user != null) 'user': user?.toMap(),
      if (attachments != null)
        'attachments': attachments?.map((e) => e.toMap()).toList(),
      if (reactions != null)
        'reactions': reactions?.map((e) => e.toMap()).toList(),
      if (answerMessage != null) 'answerMessage': answerMessage?.toMap(),
      if (forwardMessage != null) 'forwardMessage': forwardMessage?.toMap(),
      if (answerMessageId != null) 'answerMessageId': answerMessageId,
      if (forwardMessageId != null) 'forwardMessageId': forwardMessageId,
    };
  }

  Message copyWith({
    int? id,
    int? chatId,
    int? userId,
    String? text,
    String? time,
    LinkPreview? linkPreview,
    InviteData? inviteData,
    UserModel? user,
    List<FileMessage>? attachments,
    List<ReactionMessage>? reactions,
    Message? answerMessage,
    Message? forwardMessage,
    int? answerMessageId,
    int? forwardMessageId,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      time: time ?? this.time,
      linkPreview: linkPreview ?? this.linkPreview,
      inviteData: inviteData ?? this.inviteData,
      user: user ?? this.user,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      answerMessage: answerMessage ?? this.answerMessage,
      forwardMessage: forwardMessage ?? this.forwardMessage,
      answerMessageId: answerMessageId ?? this.answerMessageId,
      forwardMessageId: forwardMessageId ?? this.forwardMessageId,
    );
  }

  // Геттеры
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;

  bool get hasReactions => reactions != null && reactions!.isNotEmpty;

  bool get isAnswer => answerMessage != null;

  bool get isForward => forwardMessage != null;

  bool get hasLinkPreview => linkPreview != null;

  bool get hasInvite => inviteData != null;

  int? get amountFiles => attachments?.length;

  @override
  List<Object?> get props => [
    id,
    chatId,
    userId,
    text,
    time,
    linkPreview,
    inviteData,
    user,
    attachments,
    reactions,
    answerMessage,
    forwardMessage,
    amountFiles,
  ];
}
