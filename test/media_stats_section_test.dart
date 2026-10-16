import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/media_stats.dart';
import 'package:disalive/domain/repositories/media_stats_repository.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:disalive/presentation/features/profile/solo_chat_profile_screen.dart';
import 'package:disalive/presentation/features/profile/widgets/media_stats_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _StatsRepository implements MediaStatsRepository {
  final stats = const {
    8: MediaStats(
      chatId: 8,
      photos: 8,
      videos: 2,
      files: 3,
      audio: 4,
      links: 17,
      mutualChatsCount: 5,
    ),
  };

  @override
  Future<Either<Failure, Map<int, MediaStats>>> getAll() async => Right(stats);

  @override
  Map<int, MediaStats> getCached() => stats;

  @override
  void clear() {}
}

void main() {
  testWidgets(
    'shows five media counts and mutual groups only for direct chat',
    (tester) async {
      final bloc = MediaStatsBloc(_StatsRepository())
        ..add(const LoadMediaStats());
      addTearDown(bloc.close);

      Widget screen(
        bool direct, {
        ValueChanged<MediaStatsCategory>? onCategoryTap,
      }) => BlocProvider.value(
        value: bloc,
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: MediaStatsSection(
                chatId: 8,
                showMutualChats: direct,
                onCategoryTap: onCategoryTap,
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(screen(false));
      await tester.pumpAndSettle();
      for (final title in [
        'Изображения',
        'Видео',
        'Файлы',
        'Аудиофайлы',
        'Ссылки',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Общие группы'), findsNothing);
      expect(find.text('17'), findsOneWidget);
      final labels = ['Изображения', 'Видео', 'Файлы', 'Аудиофайлы', 'Ссылки'];
      final positions = labels
          .map((title) => tester.getTopLeft(find.text(title)))
          .toList();
      expect(positions.map((point) => point.dx).toSet(), hasLength(1));
      for (var i = 1; i < positions.length; i++) {
        expect(positions[i].dy, greaterThan(positions[i - 1].dy));
      }

      final selected = <MediaStatsCategory>[];
      await tester.pumpWidget(screen(true, onCategoryTap: selected.add));
      await tester.pumpAndSettle();
      expect(find.text('Общие группы'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      for (final title in [...labels, 'Общие группы']) {
        await tester.tap(find.text(title));
      }
      expect(selected, MediaStatsCategory.values);
    },
  );

  testWidgets('saved chat profile has title and only media counters', (
    tester,
  ) async {
    final bloc = MediaStatsBloc(_StatsRepository())
      ..add(const LoadMediaStats());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const CupertinoApp(
          home: SoloChatProfileScreen(
            chat: Chat(id: 8, name: 'Избранное', isSoloChat: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Избранное'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Избранное')).textAlign,
      TextAlign.left,
    );
    expect(find.text('Изображения'), findsOneWidget);
    expect(find.text('Общие группы'), findsNothing);
  });
}
