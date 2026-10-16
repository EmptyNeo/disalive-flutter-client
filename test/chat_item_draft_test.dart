import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/local_chat_state_repository.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoUserRepository implements UserRepository {
  @override
  UserModel? getCurrentUser() => null;

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
