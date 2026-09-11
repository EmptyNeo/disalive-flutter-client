// lib/presentation/features/chat/bloc/chat_event.dart
part of 'chat_bloc.dart';

@immutable
abstract class ChatEvent {}

class GetChats extends ChatEvent {}

// В ChatEvent:
class AddMessageToChat extends ChatEvent {
  final Message message;
  final bool isSelf;

  AddMessageToChat({required this.message, required this.isSelf});
}

class AddChat extends ChatEvent {
  final Chat chat;

  AddChat(this.chat);
}

class UpdateChat extends ChatEvent {
  final Chat chat;

  UpdateChat(this.chat);
}

class DeleteChat extends ChatEvent {
  final int chatId;

  DeleteChat(this.chatId);
}

// В chat_event.dart добавьте:
class UpdateUserInChat extends ChatEvent {
  final UserModel user;
  final bool isUpdateBlock;

  UpdateUserInChat(this.user, this.isUpdateBlock);
}

class SearchChats extends ChatEvent {
  final String query;

  SearchChats(this.query);
}

class UpdateMemberInChat extends ChatEvent {
  final int chatId;
  final int userId;
  final Member member;
  final bool isSelf;

  UpdateMemberInChat({
    required this.chatId,
    required this.userId,
    required this.member,
    required this.isSelf,
  });
}

class AddMembersToChat extends ChatEvent {
  final int? chatId;
  final List<Member> newMembers;
  final int memberCount;

  AddMembersToChat({
    required this.chatId,
    required this.newMembers,
    required this.memberCount,
  });
}

class RemoveMemberFromChat extends ChatEvent {
  final int? chatId;
  final int removedUserId;
  final int memberCount;

  RemoveMemberFromChat({
    required this.chatId,
    required this.removedUserId,
    required this.memberCount,
  });
}