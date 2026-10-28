import 'dart:io';

import 'package:disalive/data/repositories/local_chat_state_repository.dart';
import 'package:disalive/domain/enums/file_content_type.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/chat_attachment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'stores text, reply, edit target and scroll position per chat',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalChatStateRepository(prefs);

      final pending = storage.saveDraft(4, 12, const ChatDraft(text: 'Сейчас'));
      expect(storage.getDraft(4, 12)?.text, 'Сейчас');
      await pending;

      await storage.saveDraft(
        4,
        10,
        const ChatDraft(
          text: 'Привет',
          answerMessage: Message(id: 17, text: 'Ответ'),
        ),
      );
      await storage.saveDraft(
        4,
        11,
        const ChatDraft(text: 'Изменение', editingMessageId: 28),
      );
      await storage.saveFirstVisibleMessageId(4, 10, 42);

      final reopened = LocalChatStateRepository(prefs);
      expect(reopened.getDraft(4, 10)?.text, 'Привет');
      expect(reopened.getDraft(4, 10)?.answerMessage?.id, 17);
      expect(reopened.getDraft(4, 11)?.editingMessageId, 28);
      expect(reopened.getFirstVisibleMessageId(4, 10), 42);
      expect(reopened.getDraft(5, 10), isNull);
      expect(reopened.getFirstVisibleMessageId(4, 11), isNull);

      await reopened.saveDraft(4, 10, const ChatDraft());
      expect(reopened.getDraft(4, 10), isNull);
      expect(reopened.getFirstVisibleMessageId(4, 10), 42);
    },
  );

  test('copies attached files into persistent local storage', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final directory = await Directory.systemTemp.createTemp('chat_draft_test_');
    addTearDown(() => directory.delete(recursive: true));
    final original = File('${directory.path}/original.txt');
    await original.writeAsString('attachment');
    final storage = LocalChatStateRepository(
      prefs,
      directoryProvider: () async => Directory('${directory.path}/support'),
    );

    await storage.saveDraft(
      4,
      10,
      ChatDraft(
        attachments: [
          ChatAttachment(
            file: original,
            name: 'original.txt',
            size: 10,
            unit: 'Б',
            fileType: FileType.file,
            contentType: FileContentType.defaultFile,
          ),
        ],
      ),
    );
    await original.delete();

    final restored = LocalChatStateRepository(prefs).getDraft(4, 10);
    expect(restored?.attachments, hasLength(1));
    expect(
      await restored!.attachments.single.file!.readAsString(),
      'attachment',
    );
  });

  test('persists bottom and history action positions across sessions', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalChatStateRepository(prefs);

    await storage.saveChatPosition(4, 10, const ChatPosition.bottom());
    await storage.saveChatPosition(
      4,
      11,
      const ChatPosition.historyAction(27, 145),
    );

    final reopened = LocalChatStateRepository(prefs);
    expect(reopened.getChatPosition(4, 10)?.kind, ChatPositionKind.bottom);
    final action = reopened.getChatPosition(4, 11);
    expect(action?.kind, ChatPositionKind.historyAction);
    expect(action?.id, 27);
    expect(action?.aroundMessageId, 145);
    expect(reopened.getFirstVisibleMessageId(4, 11), isNull);
  });

  test('reads older numeric message positions', () async {
    SharedPreferences.setMockInitialValues({'chat_4_10_position': 91});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalChatStateRepository(prefs);

    expect(storage.getChatPosition(4, 10)?.kind, ChatPositionKind.message);
    expect(storage.getChatPosition(4, 10)?.id, 91);
  });
}
