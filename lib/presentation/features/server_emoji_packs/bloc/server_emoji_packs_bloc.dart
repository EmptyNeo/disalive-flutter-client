import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server_emoji_pack.dart';
import 'package:disalive/domain/repositories/server_emoji_pack_repository.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:equatable/equatable.dart';

part 'server_emoji_packs_event.dart';
part 'server_emoji_packs_state.dart';

class ServerEmojiPacksBloc
    extends Bloc<ServerEmojiPacksEvent, ServerEmojiPacksState> {
  final ServerEmojiPackRepository _repository;

  ServerEmojiPacksBloc(this._repository)
    : super(const ServerEmojiPacksState()) {
    on<LoadServerEmojiPacks>(_onLoad);
    on<CreateServerEmojiPack>(
      (event, emit) => _runMutation(
        event.serverId,
        emit,
        () => _repository.createPack(event.serverId),
      ),
    );
    on<UploadServerEmoji>(
      (event, emit) => _runMutation(
        event.serverId,
        emit,
        () => _repository.uploadEmoji(
          serverId: event.serverId,
          name: event.name,
          file: event.file,
        ),
      ),
    );
    on<DeleteServerEmoji>(
      (event, emit) => _runMutation(
        event.serverId,
        emit,
        () => _repository.deleteEmoji(event.emojiId),
      ),
    );
    on<DeleteServerEmojiPack>(
      (event, emit) => _runMutation(
        event.serverId,
        emit,
        () => _repository.deletePack(event.serverId),
      ),
    );
    on<SetServerEmojiPackInstalled>(
      (event, emit) => _runMutation(
        event.serverId,
        emit,
        () => _repository.installPack(
          packId: event.packId,
          installed: event.installed,
        ),
      ),
    );
  }

  Future<void> _onLoad(
    LoadServerEmojiPacks event,
    Emitter<ServerEmojiPacksState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ServerEmojiPacksStatus.loading,
        serverId: event.serverId,
        clearFailure: true,
      ),
    );
    await _load(event.serverId, emit);
  }

  Future<void> _runMutation<T>(
    int serverId,
    Emitter<ServerEmojiPacksState> emit,
    Future<Either<Failure, T>> Function() action,
  ) async {
    emit(state.copyWith(isWorking: true, clearFailure: true));
    final result = await action();
    await result.fold<Future<void>>(
      (failure) async =>
          emit(state.copyWith(isWorking: false, failure: failure)),
      (_) => _load(serverId, emit, isWorking: false),
    );
  }

  Future<void> _load(
    int serverId,
    Emitter<ServerEmojiPacksState> emit, {
    bool isWorking = false,
  }) async {
    final result = await _repository.getPacks(serverId: serverId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ServerEmojiPacksStatus.failure,
          serverId: serverId,
          failure: failure,
          isWorking: isWorking,
        ),
      ),
      (packs) {
        EmojisHandler.instance.updateServerEmojiPacksForServer(serverId, packs);
        emit(
          state.copyWith(
            status: ServerEmojiPacksStatus.loaded,
            serverId: serverId,
            packs: packs,
            isWorking: isWorking,
            clearFailure: true,
          ),
        );
      },
    );
  }
}
