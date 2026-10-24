import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/media_filter_category.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/domain/repositories/media_filter_repository.dart';
import 'package:disalive/presentation/features/media_filters/bloc/media_filters_bloc.dart';
import 'package:disalive/presentation/features/media_filters/media_filter_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _MediaRepository implements MediaFilterRepository {
  final offsets = <int>[];

  @override
  Future<Either<Failure, List<MediaFilterFile>>> getPhotos(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) async {
    expect(chatId, 42);
    expect(limit, 25);
    offsets.add(offset);
    final count = offset == 0 ? 25 : 1;
    return Right(
      List.generate(
        count,
        (index) => MediaFilterFile(
          idFilesMessage: offset + index,
          pathFile: 'https://example.com/$index.jpg',
          idMessage: offset + index,
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, List<MediaFilterMutualGroup>>> getMutualGroups(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) async => const Right([
    MediaFilterMutualGroup(idChat: 7, name: 'Общая группа', memberCount: 4),
  ]);

  @override
  Future<Either<Failure, List<MediaFilterMutualServer>>> getMutualServers(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) async => const Right([
    MediaFilterMutualServer(
      idServer: 12,
      name: 'Общий сервер',
      memberCount: 42,
    ),
  ]);

  @override
  Future<Either<Failure, List<MediaFilterLink>>> getLinks(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) async => const Right([
    MediaFilterLink(
      link: 'https://example.com/october',
      idMessage: 2,
      time: '2026-10-23 10:20:30',
      fkSender: 1,
      domain: 'example.com',
    ),
    MediaFilterLink(
      link: 'https://example.com/september',
      idMessage: 1,
      time: '2026-09-14 08:10:00',
      fkSender: 1,
      domain: 'example.com',
    ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('loads the next page once and stops after the short page', () async {
    final repository = _MediaRepository();
    final bloc = MediaFiltersBloc(repository);
    addTearDown(bloc.close);

    final firstPage = bloc.stream.firstWhere(
      (state) => !state.isLoading && state.items.length == 25,
    );
    bloc.add(
      const LoadMediaFilter(chatId: 42, category: MediaFilterCategory.photos),
    );
    expect((await firstPage).hasMore, isTrue);

    final secondPage = bloc.stream.firstWhere(
      (state) => !state.isLoadingMore && state.items.length == 26,
    );
    bloc.add(const LoadMoreMediaFilter());
    final finalState = await secondPage;
    expect(finalState.hasMore, isFalse);
    expect(repository.offsets, [0, 25]);

    bloc.add(const LoadMoreMediaFilter());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repository.offsets, [0, 25]);
  });

  testWidgets('shows the selected category and opens a mutual group', (
    tester,
  ) async {
    final bloc = MediaFiltersBloc(_MediaRepository())
      ..add(
        const LoadMediaFilter(
          chatId: 42,
          category: MediaFilterCategory.mutualChats,
        ),
      );
    addTearDown(bloc.close);
    MediaFilterMutualGroup? opened;

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: CupertinoApp(
          home: MediaFilterScreen(
            category: MediaFilterCategory.mutualChats,
            onGroupTap: (group) => opened = group,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Общие группы'), findsOneWidget);
    expect(find.text('Общая группа'), findsOneWidget);
    await tester.tap(find.text('Общая группа'));
    expect(opened?.idChat, 7);
  });

  testWidgets('shows mutual servers and invokes its callback', (tester) async {
    final bloc = MediaFiltersBloc(_MediaRepository())
      ..add(
        const LoadMediaFilter(
          chatId: 42,
          category: MediaFilterCategory.mutualServers,
        ),
      );
    addTearDown(bloc.close);
    MediaFilterMutualServer? opened;

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: CupertinoApp(
          home: MediaFilterScreen(
            category: MediaFilterCategory.mutualServers,
            onServerTap: (server) => opened = server,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Общие серверы'), findsOneWidget);
    expect(find.text('Общий сервер'), findsOneWidget);
    await tester.tap(find.text('Общий сервер'));
    expect(opened?.idServer, 12);
  });

  testWidgets('groups dated links by month and shows each day', (tester) async {
    final bloc = MediaFiltersBloc(_MediaRepository())
      ..add(const LoadMediaFilter(
        chatId: 42,
        category: MediaFilterCategory.links,
      ));
    addTearDown(bloc.close);

    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: const CupertinoApp(
        home: MediaFilterScreen(category: MediaFilterCategory.links),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Октябрь 2026'), findsOneWidget);
    expect(find.text('23 окт.'), findsOneWidget);
    expect(find.text('Сентябрь 2026'), findsOneWidget);
    expect(find.text('14 сент.'), findsOneWidget);
  });

  testWidgets('long press on a link offers only navigation to its message', (
    tester,
  ) async {
    final bloc = MediaFiltersBloc(_MediaRepository())
      ..add(const LoadMediaFilter(
        chatId: 42,
        category: MediaFilterCategory.links,
      ));
    addTearDown(bloc.close);
    int? selectedMessageId;

    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: CupertinoApp(
        home: MediaFilterScreen(
          category: MediaFilterCategory.links,
          onMessageTap: (id) => selectedMessageId = id,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('https://example.com/october'));
    await tester.pumpAndSettle();
    expect(find.text('Перейти к сообщению'), findsOneWidget);
    await tester.tap(find.text('Перейти к сообщению'));
    await tester.pumpAndSettle();
    expect(selectedMessageId, 2);
  });
}
