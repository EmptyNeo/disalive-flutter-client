// lib/presentation/features/chat/bloc/chat_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:flutter/cupertino.dart';

part 'chat_event.dart';

part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;

  ChatBloc(this._chatRepository) : super(ChatInitial()) {
    on<GetChats>(_onGetChats);
  }

  Future<void> _onGetChats(GetChats event, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    final cachedChats = _chatRepository.getCached();
    if (cachedChats.isNotEmpty) {
      emit(ChatLoaded(cachedChats));
    }

    final result = await _chatRepository.get();

    result.fold(
      (failure) {
        emit(ChatFailure(failure.message));
      },
      (chats) {
        emit(ChatLoaded(chats));
      },
    );
  }
}
