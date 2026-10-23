import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/local_chat_state_repository.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_item.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoUserRepository implements UserRepository {
  _NoUserRepository([this.user]);

  final UserModel? user;

  @override
  UserModel? getCurrentUser() => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SaveDraftOnDispose extends StatefulWidget {
  const _SaveDraftOnDispose(this.storage);

  final LocalChatStateRepository storage;

  @override
  State<_SaveDraftOnDispose> createState() => _SaveDraftOnDisposeState();
}

class _SaveDraftOnDisposeState extends State<_SaveDraftOnDispose> {
  @override
  void dispose() {
    widget.storage.saveDraft(null, 20, const ChatDraft(text: 'Набрано'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Chat keeps last message fields through map and copy', () {
    final chat = Chat.fromMap({
      'chatId': 7,
      'name': 'Беседа',
      'lastMessageText': 'Привет',
      'lastMessageUserId': 42,
    });

    expect(chat.lastMessageText, 'Привет');
    expect(chat.lastMessageUserId, 42);
    expect(chat.toMap()['lastMessageText'], 'Привет');
    expect(chat.toMap()['lastMessageUserId'], 42);
    expect(chat.copyWith(lastMessageText: 'Пока').lastMessageText, 'Пока');
    final cleared = chat.copyWith(
      clearLastMessageText: true,
      clearLastMessageUserId: true,
    );
    expect(cleared.lastMessageText, isNull);
    expect(cleared.lastMessageUserId, isNull);
  });

  testWidgets('last message replaces member count and draft takes priority', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalChatStateRepository(prefs);
    await sl.reset();
    sl.registerSingleton<LocalChatStateRepository>(storage);
    sl.registerSingleton<UserRepository>(
      _NoUserRepository(const UserModel(id: 42)),
    );
    addTearDown(sl.reset);

    Future<void> show(Chat chat) => tester.pumpWidget(
      CupertinoApp(
        home: ChatItem(chat: chat, isReconnect: false, onLongPress: null),
      ),
    );

    const chat = Chat(
      id: 7,
      name: 'Беседа',
      memberCount: 12,
      lastMessageText: 'Привет',
      lastMessageUserId: 42,
    );
    await show(chat);
    expect(find.text('Вы: Привет'), findsOneWidget);
    expect(find.text('12 участников'), findsNothing);

    await show(chat.copyWith(lastMessageUserId: 9));
    expect(find.text('Привет'), findsOneWidget);
    expect(find.text('Вы: Привет'), findsNothing);

    await storage.saveDraft(42, chat.id, const ChatDraft(text: 'Ответ'));
    await tester.pump();
    expect(find.text('Черновик: Ответ'), findsOneWidget);
    expect(find.text('Привет'), findsNothing);
  });

  testWidgets(
    'last message renders custom emoji after the own-message prefix',
    (tester) async {
      await tester.runAsync(() => EmojisHandler.instance.initialize());
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await sl.reset();
      sl.registerSingleton<LocalChatStateRepository>(
        LocalChatStateRepository(prefs),
      );
      sl.registerSingleton<UserRepository>(
        _NoUserRepository(const UserModel(id: 42)),
      );
      addTearDown(sl.reset);

      await tester.pumpWidget(
        const CupertinoApp(
          home: ChatItem(
            chat: Chat(
              id: 7,
              name: 'Беседа',
              lastMessageText: 'Привет [people:0]!',
              lastMessageUserId: 42,
            ),
            isReconnect: false,
            onLongPress: null,
          ),
        ),
      );

      expect(find.byType(EmojiWidget), findsOneWidget);
      expect(
        tester.widget<EmojiWidget>(find.byType(EmojiWidget)).animate,
        isFalse,
      );
      expect(find.textContaining('Вы: Привет'), findsOneWidget);
    },
  );

  for (final chat in [
    const Chat(id: 1, name: 'Группа', memberCount: 12),
    const Chat(id: 2, name: 'Личный', isPersonal: true),
    const Chat(id: 3, name: 'Избранное', isSoloChat: true),
  ]) {
    testWidgets('draft replaces subtitle in ${chat.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalChatStateRepository(prefs);
      await sl.reset();
      sl.registerSingleton<LocalChatStateRepository>(storage);
      sl.registerSingleton<UserRepository>(_NoUserRepository());
      addTearDown(sl.reset);

      await storage.saveDraft(null, chat.id, const ChatDraft(text: 'Текст'));
      await tester.pumpWidget(
        CupertinoApp(
          home: ChatItem(chat: chat, isReconnect: false, onLongPress: null),
        ),
      );

      expect(find.text('Черновик: Текст'), findsOneWidget);
      if (chat.isGroup) expect(find.text('12 участников'), findsNothing);
      final label = tester.widget<Text>(find.text('Черновик: Текст'));
      expect(label.style?.color, const Color(0xFFED3F49));

      await storage.saveDraft(null, chat.id, const ChatDraft());
      await tester.pump();
      expect(find.text('Черновик: Текст'), findsNothing);
    });
  }

  testWidgets(
    'draft notification during route teardown does not rebuild a locked tree',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalChatStateRepository(prefs);
      await sl.reset();
      sl.registerSingleton<LocalChatStateRepository>(storage);
      sl.registerSingleton<UserRepository>(_NoUserRepository());
      addTearDown(sl.reset);

      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ChatItem(
                    chat: Chat(id: 20, name: 'Чат', isPersonal: true),
                    isReconnect: false,
                    onLongPress: null,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: visible,
                    builder: (context, show, _) => show
                        ? _SaveDraftOnDispose(storage)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      visible.value = false;
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Черновик: Набрано'), findsOneWidget);
    },
  );
}
