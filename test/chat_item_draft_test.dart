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
}
