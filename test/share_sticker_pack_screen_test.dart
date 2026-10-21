import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';
import 'package:disalive/domain/repositories/stickers_repository.dart';
import 'package:disalive/domain/repositories/user_stickers_pack_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/stickers/share_sticker_pack_screen.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/features/stickers/widgets/sticker_pack_view_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _ChatRepository implements ChatRepository {
  @override
  void clear() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessageRepository implements MessageRepository {
  @override
  void clearAllCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReactionsRepository implements ReactionsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserRepository implements UserRepository {
  @override
  UserModel? getCurrentUser() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Packs implements StickerPackRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserPacks implements UserStickersPackRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Stickers implements StickersRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ChatBloc extends ChatBloc {
  _ChatBloc(super.repository, super.bus);

  void showChats() => emit(
    ChatLoaded(const [
      Chat(id: 4, name: 'Алиса', isPersonal: true),
      Chat(id: 5, name: 'Боб', isPersonal: true),
    ], 0),
  );
}

class _MessageBloc extends MessageBloc {
  _MessageBloc(super.messages, super.reactions, super.chats, super.bus);

  CreateMessage? lastCreated;

  @override
  void add(MessageEvent event) {
    if (event is CreateMessage) lastCreated = event;
  }
}

void main() {
  testWidgets('share action in pack sheet opens chat sharing screen', (
    tester,
  ) async {
    await sl.reset();
    final bus = WsEventBus();
    final chats = _ChatRepository();
    final chatBloc = _ChatBloc(chats, bus)..showChats();
    final messageBloc = _MessageBloc(
      _MessageRepository(),
      _ReactionsRepository(),
      chats,
      bus,
    );
    final stickersBloc = StickersPackBloc(_Packs(), _UserPacks(), _Stickers());
    const pack = StickerPack(
      id: 42,
      name: 'Коты',
      isCreator: false,
      attachments: [],
      hasPack: false,
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ChatBloc>.value(value: chatBloc),
          BlocProvider<MessageBloc>.value(value: messageBloc),
          BlocProvider<StickersPackBloc>.value(value: stickersBloc),
        ],
        child: CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => StickerPackViewBottomSheet.open(
                context,
                pack: pack,
                onStickerTap: (_) {},
              ),
              child: const Text('Открыть набор'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть набор'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Поделиться'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ShareStickerPackScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await stickersBloc.close();
      await chatBloc.close();
      await messageBloc.close();
      bus.dispose();
      await sl.reset();
    });
  });

  testWidgets('share screen filters personal chats and sends pack URL', (
    tester,
  ) async {
    await sl.reset();
    sl.registerSingleton<UserRepository>(_UserRepository());
    final bus = WsEventBus();
    final chats = _ChatRepository();
    final chatBloc = _ChatBloc(chats, bus)..showChats();
    final messageBloc = _MessageBloc(
      _MessageRepository(),
      _ReactionsRepository(),
      chats,
      bus,
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ChatBloc>.value(value: chatBloc),
          BlocProvider<MessageBloc>.value(value: messageBloc),
        ],
        child: CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => ShareStickerPackScreen.open(
                context,
                pack: const StickerPack(
                  id: 42,
                  name: 'Коты',
                  isCreator: false,
                  attachments: [],
                  hasPack: false,
                ),
              ),
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ShareStickerPackScreen), findsOneWidget);
    expect(find.text('Алиса'), findsOneWidget);
    expect(find.text('Боб'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextField), 'Алиса');
    await tester.pump();
    expect(find.text('Боб'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('send_invite_4')));
    await tester.pump();
    expect(messageBloc.lastCreated?.chatId, 4);
    expect(messageBloc.lastCreated?.entityId, 4);
    expect(messageBloc.lastCreated?.entityType, EntityType.chat);
    expect(
      messageBloc.lastCreated?.message.text,
      'https://disalive.ru/addstickers/index.php?packId=42',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await chatBloc.close();
      await messageBloc.close();
      bus.dispose();
      await sl.reset();
    });
  });
}
