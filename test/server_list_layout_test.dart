import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server_list_layout.dart';
import 'package:disalive/domain/repositories/server_list_repository.dart';
import 'package:disalive/presentation/features/server/bloc/server_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _ServerListRepository implements ServerListRepository {
  ServerListLayout stored = ServerListLayout([
    const ServerListItem.folder(folderId: 8, name: 'Работа', servers: [2]),
    const ServerListItem.server(1),
  ]);
  bool failSave = false;

  @override
  Future<Either<Failure, ServerListLayout>> getLayout() async => Right(stored);

  @override
  Future<Either<Failure, ServerListLayout>> saveLayout(
    ServerListLayout layout,
  ) async {
    if (failSave) return Left(ClientFailure('Не удалось сохранить'));
    var nextId = 9;
    stored = ServerListLayout([
      for (final item in layout.items)
        item.isFolder && item.folderId == null
            ? ServerListItem.folder(
                folderId: nextId++,
                name: item.name!,
                servers: item.servers,
              )
            : item,
    ]);
    return Right(stored);
  }
}

void main() {
  test('layout keeps folders and includes new memberships once', () {
    final layout = ServerListLayout.fromMap({
      'items': [
        {
          'type': 'folder',
          'folderId': 8,
          'name': 'Работа',
          'servers': [2, 1],
        },
        {'type': 'server', 'serverId': 1},
        {'type': 'server', 'serverId': 99},
      ],
    }).reconcile([1, 2, 3]);
    expect(layout.items[0].servers, [2, 1]);
    expect(layout.items[1].serverId, 3);
    expect(layout.items.length, 2);
  });

  test(
    'folder creation, move and failed save preserve canonical layout',
    () async {
      final repo = _ServerListRepository();
      final cubit = ServerListCubit(repo);
      cubit.syncServers([1, 2, 3]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.layout.items.last.serverId, 3);

      await cubit.createFolder('Игры');
      expect(cubit.state.layout.items.last.folderId, 9);
      await cubit.moveServer(3, folderId: 9);
      expect(cubit.state.layout.items.last.servers, [3]);

      repo.failSave = true;
      await cubit.deleteFolder(8);
      expect(cubit.state.layout.items.first.folderId, 8);
      expect(cubit.state.error, 'Не удалось сохранить');
      await cubit.close();
    },
  );

  test(
    'dragging onto a server creates a folder at the target position',
    () async {
      final repo = _ServerListRepository();
      final cubit = ServerListCubit(repo);
      cubit.syncServers([1, 2, 3]);
      await Future<void>.delayed(Duration.zero);

      await cubit.groupServers(3, 1);
      expect(cubit.state.layout.items[1].servers, [1, 3]);
      expect(cubit.state.layout.items[1].folderId, 9);
      expect(cubit.state.layout.items.length, 2);
      await cubit.close();
    },
  );

  test('dragging the last server out removes its empty folder', () async {
    final repo = _ServerListRepository();
    final cubit = ServerListCubit(repo);
    cubit.syncServers([1, 2]);
    await Future<void>.delayed(Duration.zero);

    await cubit.placeAtRoot(
      const ServerListItem.server(2),
      const ServerListItem.folder(folderId: 8, name: 'Работа', servers: [2]),
      after: true,
    );
    expect(cubit.state.layout.items.map((item) => item.serverId), [2, 1]);
    await cubit.close();
  });

  test('reordering inside a folder accounts for the removed source', () async {
    final repo = _ServerListRepository();
    repo.stored = const ServerListLayout([
      ServerListItem.folder(folderId: 8, name: 'Работа', servers: [1, 2, 3]),
    ]);
    final cubit = ServerListCubit(repo);
    cubit.syncServers([1, 2, 3]);
    await Future<void>.delayed(Duration.zero);

    await cubit.placeServerInFolder(2, 8, index: 2);
    expect(cubit.state.layout.items.single.servers, [1, 2, 3]);
    await cubit.placeServerInFolder(2, 8, index: 3);
    expect(cubit.state.layout.items.single.servers, [1, 3, 2]);
    await cubit.close();
  });
}
