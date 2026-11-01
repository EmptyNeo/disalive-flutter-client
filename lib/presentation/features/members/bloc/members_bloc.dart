// presentation/features/members/bloc/members_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

part 'members_event.dart';

part 'members_state.dart';

class MembersBloc extends Bloc<MembersEvent, MembersState> {
  final MembersRepository _membersRepository;
  final WsEventBus _eventBus;

  StreamSubscription<WsEvent>? _createSubscription;
  StreamSubscription<WsEvent>? _deleteSubscription;
  StreamSubscription<WsEvent>? _updateSubscription;
  StreamSubscription<WsEvent>? _userUpdateSubscription;
  StreamSubscription<WsEvent>? _moderationSubscription;

  MembersBloc(this._membersRepository, this._eventBus)
    : super(MembersInitial()) {
    on<GetMembers>(_onGetMembers);
    on<MemberAddedEvent>(_onMemberAdded);
    on<MemberRemovedEvent>(_onMemberRemoved);
    on<MemberUpdatedEvent>(_onMemberUpdated);
    on<MemberModerationUpdatedEvent>(_onMemberModerationUpdated);
    on<UpdateUserInMembers>(_onUpdateUserInMembers);
  }

  void setupListeners() {
    closeSubs();

    _createSubscription = _eventBus.subscribe(
      table: 'ChatMembers',
      action: ActionType.create,
      onData: (event) {
        final membersData = event.data['members'];
        final entityId = DataParser.parseInt(event.data['entityId']);
        final entityTypeStr = event.data['entityType'];
        final memberCount = event.data['memberCount'] ?? 0;

        if (membersData is List && entityId != null && entityTypeStr != null) {
          final newMembers = membersData
              .map((e) => Member.fromMap(e as Map<String, dynamic>))
              .toList();

          add(
            MemberAddedEvent(
              entityId: entityId,
              entityType: EntityType.fromString(entityTypeStr),
              newMembers: newMembers,
              memberCount: memberCount,
            ),
          );
        }
      },
    );

    _deleteSubscription = _eventBus.subscribe(
      table: 'ChatMembers',
      action: ActionType.delete,
      onData: (event) {
        final entityId = DataParser.parseInt(event.data['entityId']);
        final entityTypeStr = event.data['entityType'];
        final removedUserId = event.data['userId']; // Из leave.php и remove.php
        final memberCount = event.data['memberCount'] ?? 0;

        if (entityId != null &&
            entityTypeStr != null &&
            removedUserId != null) {
          add(
            MemberRemovedEvent(
              entityId: entityId,
              entityType: EntityType.fromString(entityTypeStr),
              removedUserId: removedUserId,
              memberCount: memberCount,
            ),
          );
        }
      },
    );

    _updateSubscription = _eventBus.subscribe(
      table: 'ChatMembers',
      action: ActionType.update,
      onData: (event) {
        final membersData = event.data['members'];
        final entityId = event.data['entityId'];
        final entityTypeStr = event.data['entityType'];

        if (membersData is List && entityId != null && entityTypeStr != null) {
          final updatedMembers = membersData
              .map((e) => Member.fromMap(e as Map<String, dynamic>))
              .toList();

          add(
            MemberUpdatedEvent(
              entityId: entityId,
              entityType: EntityType.fromString(entityTypeStr),
              updatedMembers: updatedMembers,
            ),
          );
        }
      },
    );

    _userUpdateSubscription = _eventBus.subscribe(
      table: 'User',
      action: ActionType.update,
      onData: (event) {
        final map = event.data['user'];
        if (map is Map<String, dynamic>) {
          final user = UserModel.fromMap(map);
          add(UpdateUserInMembers(user));
        }
      },
    );

    _moderationSubscription = _eventBus.subscribe(
      table: 'EntityModeration',
      action: ActionType.update,
      onData: (event) {
        final entityId = DataParser.parseInt(event.data['entityId']);
        final entityTypeValue = event.data['entityType'];
        var userId = DataParser.parseInt(event.data['userId']);
        final action = event.data['action'] as String?;
        final active = DataParser.parseBool(event.data['active']) ?? false;
        if (userId == null &&
            action == 'ban' &&
            !active &&
            event.isSelf &&
            sl.isRegistered<UserRepository>()) {
          userId = sl<UserRepository>().getCurrentUser()?.id;
        }
        if (entityId == null ||
            entityTypeValue is! String ||
            userId == null ||
            action == null ||
            (action != 'ban' && action != 'mute')) {
          return;
        }
        add(
          MemberModerationUpdatedEvent(
            entityId: entityId,
            entityType: EntityType.fromString(entityTypeValue),
            userId: userId,
            action: action,
            active: active,
            expiresAt: event.data['expiresAt'] as String?,
          ),
        );
      },
    );
  }

  Future<void> _onGetMembers(
    GetMembers event,
    Emitter<MembersState> emit,
  ) async {
    final entityKey = EntityKey(
      entityId: event.entityId,
      entityType: event.entityType,
    );

    final cachedMembers = await _membersRepository.getCached(entityKey);

    if (cachedMembers.isNotEmpty) {
      emit(
        MembersLoaded(
          entityId: event.entityId,
          entityType: event.entityType,
          members: cachedMembers,
        ),
      );
      return;
    }

    emit(MembersLoading());

    final result = await _membersRepository.get(
      event.entityId,
      event.entityType,
    );

    result.fold((failure) => emit(MembersFailure(failure.message)), (members) {
      emit(
        MembersLoaded(
          entityId: event.entityId,
          entityType: event.entityType,
          members: members,
        ),
      );
    });
  }

  void _onMemberAdded(MemberAddedEvent event, Emitter<MembersState> emit) {
    if (state is! MembersLoaded) return;
    final currentState = state as MembersLoaded;

    // 🎯 ФИЛЬТР: Обновляем UI только если мы сейчас смотрим на эту же сущность
    if (currentState.entityId != event.entityId ||
        currentState.entityType != event.entityType) {
      return;
    }

    // Добавляем новых участников в конец списка (или можно отсортировать, если нужно)
    final updatedMembers = [...currentState.members, ...event.newMembers];

    // Обновляем кэш репозитория, чтобы при следующем открытии данные были свежими
    _updateRepositoryCache(event.entityId, event.entityType, updatedMembers);

    emit(
      MembersLoaded(
        entityId: event.entityId,
        entityType: event.entityType,
        members: updatedMembers,
        memberCount: event.memberCount,
      ),
    );
  }

  void _onMemberRemoved(MemberRemovedEvent event, Emitter<MembersState> emit) {
    if (state is! MembersLoaded) return;
    final currentState = state as MembersLoaded;

    if (currentState.entityId != event.entityId ||
        currentState.entityType != event.entityType) {
      return;
    }

    // Удаляем участника по fkUser (ID пользователя)
    final updatedMembers = currentState.members
        .where((m) => m.fkUser != event.removedUserId)
        .toList();

    _updateRepositoryCache(event.entityId, event.entityType, updatedMembers);

    emit(
      MembersLoaded(
        entityId: event.entityId,
        entityType: event.entityType,
        members: updatedMembers,
        memberCount: event.memberCount,
      ),
    );
  }

  void _onMemberUpdated(MemberUpdatedEvent event, Emitter<MembersState> emit) {
    if (state is! MembersLoaded) return;
    final currentState = state as MembersLoaded;

    if (currentState.entityId != event.entityId ||
        currentState.entityType != event.entityType) {
      return;
    }

    final updatedMembers = List<Member>.from(currentState.members);

    // Заменяем обновленных участников в списке
    for (final newMember in event.updatedMembers) {
      final index = updatedMembers.indexWhere(
        (m) => m.fkUser == newMember.fkUser,
      );
      if (index != -1) {
        updatedMembers[index] = newMember;
      }
    }

    _updateRepositoryCache(event.entityId, event.entityType, updatedMembers);

    emit(
      MembersLoaded(
        entityId: event.entityId,
        entityType: event.entityType,
        members: updatedMembers,
        memberCount:
            currentState.memberCount, // При update count обычно не меняется
      ),
    );
  }

  Future<void> _onMemberModerationUpdated(
    MemberModerationUpdatedEvent event,
    Emitter<MembersState> emit,
  ) async {
    final entityKey = EntityKey(
      entityId: event.entityId,
      entityType: event.entityType,
    );
    final currentState = state;
    final isCurrentEntity =
        currentState is MembersLoaded &&
        currentState.entityId == event.entityId &&
        currentState.entityType == event.entityType;
    final members = isCurrentEntity
        ? currentState.members
        : await _membersRepository.getCached(entityKey);
    if (members.isEmpty) return;

    final updatedMembers = members.map((member) {
      if (member.fkUser != event.userId) return member;
      if (event.action == 'ban') {
        return member.copyWith(
          isBanned: event.active,
          banExpiresAt: event.expiresAt,
          clearBanExpiresAt: !event.active || event.expiresAt == null,
        );
      }
      return member.copyWith(
        isChatMuted: event.active,
        chatMuteExpiresAt: event.expiresAt,
        clearChatMuteExpiresAt: !event.active || event.expiresAt == null,
      );
    }).toList();

    _membersRepository.updateCache(entityKey, updatedMembers);
    final latestState = state;
    if (latestState is MembersLoaded &&
        latestState.entityId == event.entityId &&
        latestState.entityType == event.entityType) {
      emit(
        MembersLoaded(
          entityId: latestState.entityId,
          entityType: latestState.entityType,
          members: updatedMembers,
          memberCount: latestState.memberCount,
        ),
      );
    }
  }

  void _onUpdateUserInMembers(
    UpdateUserInMembers event,
    Emitter<MembersState> emit,
  ) {
    if (state is! MembersLoaded) return;
    final currentState = state as MembersLoaded;

    // Проходим по всем участникам и обновляем данные того, чей ID совпадает
    final updatedMembers = currentState.members.map((member) {
      if (member.fkUser == event.user.id) {
        return member.copyWith(user: event.user);
      }
      return member;
    }).toList();

    bool hasChanges = false;
    for (int i = 0; i < updatedMembers.length; i++) {
      if (updatedMembers[i] != currentState.members[i]) {
        hasChanges = true;
        break;
      }
    }

    if (hasChanges) {
      _updateRepositoryCache(
        currentState.entityId,
        currentState.entityType,
        updatedMembers,
      );

      emit(
        MembersLoaded(
          entityId: currentState.entityId,
          entityType: currentState.entityType,
          members: updatedMembers,
          memberCount: currentState.memberCount,
        ),
      );
    }
  }

  // Вспомогательный метод для синхронизации кэша репозитория
  void _updateRepositoryCache(
    int entityId,
    EntityType entityType,
    List<Member> members,
  ) {
    EntityKey entityKey = EntityKey(entityId: entityId, entityType: entityType);
    _membersRepository.updateCache(entityKey, members);
  }

  @override
  Future<void> close() {
    closeSubs();
    _membersRepository.clear();
    return super.close();
  }

  void closeSubs() {
    _createSubscription?.cancel();
    _deleteSubscription?.cancel();
    _updateSubscription?.cancel();
    _userUpdateSubscription?.cancel();
    _moderationSubscription?.cancel();
  }
}
