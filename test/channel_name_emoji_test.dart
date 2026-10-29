import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/features/category_channel/widgets/category_channel_item.dart';
import 'package:disalive/presentation/features/channel_server/widgets/channel_server_item.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_header.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/app_selection_sheet.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category and channel names render custom emojis', (
    tester,
  ) async {
    await tester.runAsync(() => EmojisHandler.instance.initialize());

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Column(
            children: [
              const CategoryChannelItem(
                category: CategoryChannel(name: 'Раздел [people:0]'),
              ),
              const ChannelServerItem(
                channel: ChannelServer(chatName: 'Канал [people:0]'),
              ),
              ChatHeader(
                chat: const Chat(
                  id: 1,
                  name: 'Канал [people:0]',
                  type: ChatType.channel,
                ),
                isReconnect: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(EmojiWidget), findsNWidgets(3));
    expect(find.textContaining('[people:0]'), findsNothing);
  });

  testWidgets('sheets and confirmation dialogs render emojis in names', (
    tester,
  ) async {
    await tester.runAsync(() => EmojisHandler.instance.initialize());
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => Column(
            children: [
              CupertinoButton(
                onPressed: () => ActionBottomSheet.show(
                  context,
                  title: 'Канал [people:0]',
                  actions: [
                    ActionItem(
                      icon: CupertinoIcons.pencil,
                      label: 'Редактировать',
                      onTap: () {},
                    ),
                  ],
                ),
                child: const Text('Действия'),
              ),
              CupertinoButton(
                onPressed: () => AppSelectionSheet.show<int>(
                  context,
                  title: 'Категория',
                  options: const [
                    AppSelectionOption(value: 1, label: 'Раздел [people:0]'),
                  ],
                ),
                child: const Text('Выбор'),
              ),
              CupertinoButton(
                onPressed: () => showConfirmationDialog(
                  context,
                  title: 'Удалить канал?',
                  description: 'Канал «[people:0]» будет удалён.',
                ),
                child: const Text('Удаление'),
              ),
            ],
          ),
        ),
      ),
    );

    for (final button in ['Действия', 'Выбор', 'Удаление']) {
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(find.byType(EmojiWidget), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  });
}
