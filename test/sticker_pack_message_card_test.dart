import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/link_data.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';
import 'package:disalive/domain/repositories/stickers_repository.dart';
import 'package:disalive/domain/repositories/user_stickers_pack_repository.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/features/message/widgets/link_preview.dart';
import 'package:disalive/presentation/features/message/widgets/sticker_pack_message_card.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/features/stickers/sticker_pack_link.dart';
import 'package:disalive/presentation/features/stickers/widgets/sticker_pack_view_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Packs implements StickerPackRepository {
  int? requestedId;

  @override
  Future<Either<Failure, StickerPack?>> getById(
    int packId,
    int skip,
    int take,
  ) async {
    requestedId = packId;
    return Right(
      StickerPack(
        id: packId,
        name: 'Коты',
        isCreator: false,
        attachments: const [],
        hasPack: false,
      ),
    );
  }

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

void main() {
  test('sticker URL requires a numeric packId', () {
    expect(
      stickerPackUrl(42),
      'https://disalive.ru/addstickers/index.php?packId=42',
    );
    final link = stickerPackLinkFromText(
      'Смотри https://disalive.ru/addstickers/index.php?packId=42',
    );
    expect(link?.packId, 42);
    expect(link?.url, 'https://disalive.ru/addstickers/index.php?packId=42');
    expect(
      stickerPackLinkFromText(
        'disalive.ru/addstickers/index.php?packId=7',
      )?.packId,
      7,
    );
    expect(
      stickerPackLinkFromText(
        'https://disalive.ru/addstickers/index.php?packId=abc',
      ),
      isNull,
    );
    expect(
      stickerPackLinkFromText(
        'https://disalive.ru/addstickers/index.php?packId=42x',
      ),
      isNull,
    );
    expect(
      stickerPackLinkFromText(
        'https://disalive.ru/addstickers/index.php?packId=42.5',
      ),
      isNull,
    );
    expect(
      stickerPackLinkFromText(
        'https://evil-disalive.ru/addstickers/index.php?packId=42',
      ),
      isNull,
    );
  });

  testWidgets('message keeps sticker URL and opens pack from card', (
    tester,
  ) async {
    await sl.reset();
    final packs = _Packs();
    sl.registerSingleton<StickerPackRepository>(packs);
    final bloc = StickersPackBloc(packs, _UserPacks(), _Stickers());
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: CupertinoApp(
          home: Center(
            child: MessageItem(
              message: const Message(
                text:
                    'Смотри https://disalive.ru/addstickers/index.php?packId=42',
                linkPreview: LinkData(title: 'Обычное превью'),
              ),
              isMine: false,
              isRead: true,
              showTime: false,
              onStickerTap: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.byType(StickerPackMessageCard), findsOneWidget);
    expect(find.byType(LinkPreview), findsNothing);
    expect(find.textContaining('addstickers'), findsOneWidget);
    expect(
      find.text('Нажмите для просмотра коллекции стикеров'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('sticker_pack_card_42')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(packs.requestedId, 42);
    expect(find.byType(StickerPackViewBottomSheet), findsOneWidget);
    expect(find.text('Коты'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await bloc.close();
      await sl.reset();
    });
  });

  testWidgets('sticker preview URL shows pack card instead of link preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageItem(
            message: const Message(
              text: 'Посмотри набор',
              linkPreview: LinkData(
                url: 'https://disalive.ru/addstickers/index.php?packId=42',
                title: 'Стикеры',
              ),
            ),
            isMine: false,
            isRead: true,
            showTime: false,
            onStickerTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(StickerPackMessageCard), findsOneWidget);
    expect(find.byType(LinkPreview), findsNothing);
  });

  testWidgets('plain message link opens the confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageItem(
            message: const Message(text: 'https://example.com/path'),
            isMine: false,
            isRead: true,
            showTime: false,
            onStickerTap: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.textContaining('https://example.com/path'));
    await tester.pumpAndSettle();
    expect(find.text('Открыть ссылку'), findsOneWidget);
    expect(find.text('https://example.com/path'), findsWidgets);
  });
}
