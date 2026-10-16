import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/data/repositories/local_chat_state_repository.dart';
import 'package:disalive/domain/enums/action_session_type.dart';
import 'package:disalive/domain/enums/file_content_type.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/models/ui/chat_attachment.dart';
import 'package:disalive/domain/repositories/session_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/bloc/session/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UserRepository implements UserRepository {
  _UserRepository(this.user);

  UserModel? user;

  @override
  UserModel? getCurrentUser() => user;

  @override
  void clearCurrentUser() => user = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SessionRepository implements SessionRepository {
  _SessionRepository(this.sessionId);

  final int? sessionId;
  Either<Failure, bool> deleteResult = const Right(true);
  int? deletedId;
  ActionSessionType? deletedType;

  @override
  Future<int?> getCurrentSessionId() async => sessionId;

  @override
  Future<Either<Failure, bool>> delete(int id, ActionSessionType type) async {
    deletedId = id;
    deletedType = type;
    return deleteResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SecureStorage extends SecureStorageService {
  int clears = 0;

  @override
  Future<void> clearAll() async => clears++;
}

Future<SessionState> _until(
  SessionBloc bloc,
  bool Function(SessionState) matches,
) => bloc.stream.firstWhere(matches).timeout(const Duration(seconds: 3));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logout clears only current user drafts and copied files', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final directory = await Directory.systemTemp.createTemp('logout_drafts_');
    addTearDown(() => directory.delete(recursive: true));
    final original = File('${directory.path}/photo.jpg');
    await original.writeAsBytes([1, 2, 3]);
    final drafts = LocalChatStateRepository(
      prefs,
      directoryProvider: () async => Directory('${directory.path}/support'),
    );
    final pendingDraft = drafts.saveDraft(
      4,
      10,
      ChatDraft(
        text: 'Не отправлено',
        attachments: [
          ChatAttachment(
            file: original,
            name: 'photo.jpg',
            size: 3,
            unit: 'Б',
            fileType: FileType.image,
            contentType: FileContentType.defaultFile,
          ),
        ],
      ),
    );
    await drafts.saveDraft(5, 10, const ChatDraft(text: 'Другой аккаунт'));
    await drafts.saveFirstVisibleMessageId(4, 10, 99);

    final sessions = _SessionRepository(7);
    final secure = _SecureStorage();
    final bus = WsEventBus();
    addTearDown(bus.dispose);
    final bloc = SessionBloc(
      _UserRepository(const UserModel(id: 4)),
      sessions,
      secure,
      bus,
      drafts,
    );
    addTearDown(bloc.close);

    bloc.add(Logout());
    await _until(bloc, (state) => state is SessionLoggedOut);
    await pendingDraft;

    expect(sessions.deletedId, 7);
    expect(sessions.deletedType, ActionSessionType.target);
    expect(secure.clears, 1);
    expect(drafts.getDraft(4, 10), isNull);
    expect(LocalChatStateRepository(prefs).getDraft(4, 10), isNull);
    expect(drafts.getDraft(5, 10)?.text, 'Другой аккаунт');
    expect(drafts.getFirstVisibleMessageId(4, 10), 99);
    expect(
      await Directory('${directory.path}/support/chat_drafts/4').exists(),
      isFalse,
    );

    await drafts.saveDraft(4, 10, const ChatDraft(text: 'Поздняя запись'));
    expect(drafts.getDraft(4, 10), isNull);
    drafts.allowDraftsForUser(4);
    await drafts.saveDraft(4, 10, const ChatDraft(text: 'Новая сессия'));
    expect(drafts.getDraft(4, 10)?.text, 'Новая сессия');
  });

  test('external logout and missing session also clear drafts', () async {
    for (final external in [false, true]) {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final directory = await Directory.systemTemp.createTemp('logout_drafts_');
      addTearDown(() => directory.delete(recursive: true));
      final drafts = LocalChatStateRepository(
        prefs,
        directoryProvider: () async => Directory('${directory.path}/support'),
      );
      await drafts.saveDraft(4, 10, const ChatDraft(text: 'Черновик'));
      final secure = _SecureStorage();
      final bus = WsEventBus();
      addTearDown(bus.dispose);
      final bloc = SessionBloc(
        _UserRepository(const UserModel(id: 4)),
        _SessionRepository(null),
        secure,
        bus,
        drafts,
      );
      addTearDown(bloc.close);

      bloc.add(external ? SessionClosedExternally() : Logout());
      await _until(bloc, (state) => state is SessionLoggedOut);

      expect(drafts.getDraft(4, 10), isNull);
      expect(secure.clears, 1);
    }
  });

  test('failed server logout keeps drafts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final directory = await Directory.systemTemp.createTemp('logout_drafts_');
    addTearDown(() => directory.delete(recursive: true));
    final drafts = LocalChatStateRepository(
      prefs,
      directoryProvider: () async => Directory('${directory.path}/support'),
    );
    await drafts.saveDraft(4, 10, const ChatDraft(text: 'Оставить'));
    final sessions = _SessionRepository(7)
      ..deleteResult = const Left(ServerFailure());
    final secure = _SecureStorage();
    final bus = WsEventBus();
    addTearDown(bus.dispose);
    final bloc = SessionBloc(
      _UserRepository(const UserModel(id: 4)),
      sessions,
      secure,
      bus,
      drafts,
    );
    addTearDown(bloc.close);

    bloc.add(Logout());
    await _until(bloc, (state) => state is SessionFailure);

    expect(drafts.getDraft(4, 10)?.text, 'Оставить');
    expect(secure.clears, 0);
  });
}
