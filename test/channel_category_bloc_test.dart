import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/category_channel_repository.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/category_channel/bloc/category_channel_bloc.dart';
import 'package:disalive/presentation/features/channel_server/bloc/channel_server_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _ChannelRepository implements ChannelServerRepository {
  final Map<int, List<ChannelServer>> cache = {};
  Completer<void>? release;

  @override
  Future<Either<Failure, List<ChannelServer>>> get(int serverId) async {
    await release?.future;
    final result = [
      ChannelServer(
        id: 10,
        serverId: serverId,
        chatId: 90,
        chatName: 'Original',
        newMessagesCount: 5,
      ),
    ];
    updateCache(serverId, result);
    return Right(result);
  }

  @override
  List<ChannelServer> getCached(int serverId) => cache[serverId] ?? [];

  @override
  void updateCache(int serverId, List<ChannelServer> channels) {
    cache[serverId] = List.from(channels);
  }

  @override
  ChannelServer? getByIdCached(int id) {
    for (final channels in cache.values) {
      for (final channel in channels) {
        if (channel.id == id) return channel;
      }
    }
    return null;
  }

  @override
  void clear([int? serverId]) {
    if (serverId == null) {
      cache.clear();
    } else {
      cache.remove(serverId);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CategoryRepository implements CategoryChannelRepository {
  final Map<int, List<CategoryChannel>> cache = {};
  Completer<void>? release;

  @override
  Future<Either<Failure, List<CategoryChannel>>> get(int serverId) async {
    await release?.future;
    final result = [
      CategoryChannel(id: 7, serverId: serverId, name: 'Original'),
    ];
    updateCache(serverId, result);
    return Right(result);
  }

  @override
  List<CategoryChannel> getCached(int serverId) => cache[serverId] ?? [];

  @override
  void updateCache(int serverId, List<CategoryChannel> categories) {
    cache[serverId] = List.from(categories);
  }

  @override
  CategoryChannel? getByIdCached(int id) {
    for (final categories in cache.values) {
      for (final category in categories) {
        if (category.id == id) return category;
      }
    }
    return null;
  }

  @override
  void clear([int? serverId]) {
    if (serverId == null) {
      cache.clear();
    } else {
      cache.remove(serverId);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WsEvent _ws(String table, ActionType action, Map<String, dynamic> data) =>
    WsEvent(table: table, action: action, data: data, isSelf: false);

void main() {
  test('new channel message increments unread and reading clears it', () async {
    final repository = _ChannelRepository();
    final bus = WsEventBus();
    final bloc = ChannelServerBloc(repository, bus);
    bloc.add(const GetServerChannels(2));
    await bloc.stream.firstWhere((state) => state is ServerChannelsLoaded);

    final added = bloc.stream.firstWhere(
      (state) =>
          state is ServerChannelsLoaded &&
          state.channels.first.newMessagesCount == 6,
    );
    bus.dispatch(
      _ws('Message', ActionType.create, {
        'message': {'id': 50, 'chatId': 90},
      }),
    );
    await added;

    final read = bloc.stream.firstWhere(
      (state) =>
          state is ServerChannelsLoaded &&
          state.channels.first.lastIdReadMessage == 50,
    );
    bus.dispatch(
      WsEvent(
        table: 'ChatMembers',
        action: ActionType.update,
        data: {
          'entityId': 2,
          'entityType': 'server',
          'chatId': 90,
          'isSelf': true,
          'member': {'lastIdReadMessage': 50},
        },
        isSelf: true,
      ),
    );
    await read;
    expect(repository.getByIdCached(10)?.newMessagesCount, 0);
    await bloc.close();
    bus.dispose();
  });

  test('channel member update advances read status and unread count', () async {
    final repository = _ChannelRepository();
    final bus = WsEventBus();
    final bloc = ChannelServerBloc(repository, bus);
    bloc.add(const GetServerChannels(2));
    await bloc.stream.firstWhere((state) => state is ServerChannelsLoaded);
    repository.updateCache(2, const [
      ChannelServer(
        id: 10,
        serverId: 2,
        chatId: 90,
        chatName: 'Original',
        lastIdReadMessage: 40,
        newMessagesCount: 5,
      ),
    ]);

    final updated = bloc.stream.firstWhere(
      (state) =>
          state is ServerChannelsLoaded &&
          state.channels.first.lastIdReadMessage == 43,
    );
    bus.dispatch(
      WsEvent(
        table: 'ChatMembers',
        action: ActionType.update,
        data: {
          'entityId': 2,
          'entityType': 'server',
          'chatId': 90,
          'isSelf': true,
          'member': {'lastIdReadMessage': 43, 'muted': true},
        },
        isSelf: true,
      ),
    );
    await updated;
    expect(repository.getByIdCached(10)?.newMessagesCount, 2);
    expect(repository.getByIdCached(10)?.lastIdReadMessage, 43);

    bus.dispatch(
      WsEvent(
        table: 'ChatMembers',
        action: ActionType.update,
        data: {
          'entityId': 2,
          'entityType': 'server',
          'chatId': 90,
          'isSelf': false,
          'member': {'lastIdReadMessage': 45},
        },
        isSelf: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.getByIdCached(10)?.lastIdReadMessage, 43);

    await bloc.close();
    bus.dispose();
  });

  test(
    'ChannelServerBloc filters servers and applies create/update/delete',
    () async {
      final repository = _ChannelRepository();
      final bus = WsEventBus();
      final bloc = ChannelServerBloc(repository, bus);
      final loaded = bloc.stream.firstWhere(
        (state) => state is ServerChannelsLoaded,
      );
      bloc.add(const GetServerChannels(2));
      await loaded;

      bus.dispatch(
        _ws('ChannelsServer', ActionType.create, {
          'serverId': 3,
          'channel': {'id': 99, 'serverId': 3, 'chatName': 'Other'},
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.getByIdCached(99), isNull);

      final created = bloc.stream.firstWhere(
        (state) => state is ServerChannelsLoaded && state.channels.length == 2,
      );
      bus.dispatch(
        _ws('ChannelsServer', ActionType.create, {
          'entityId': 2,
          'channel': {'id': 11, 'chatId': 91, 'chatName': 'New'},
        }),
      );
      await created;
      expect(repository.getByIdCached(11)?.serverId, 2);

      final updated = bloc.stream.firstWhere(
        (state) =>
            state is ServerChannelsLoaded &&
            state.channels.any(
              (channel) => channel.id == 10 && channel.chatName == 'Renamed',
            ),
      );
      bus.dispatch(
        _ws('ChannelsServer', ActionType.update, {
          'serverId': '2',
          'channelId': '10',
          'channel': {'chatName': 'Renamed', 'categoryId': null},
        }),
      );
      await updated;
      expect(repository.getByIdCached(10)?.newMessagesCount, 5);
      expect(repository.getByIdCached(10)?.chatId, 90);

      final removed = bloc.stream.firstWhere(
        (state) => state is ServerChannelsLoaded && state.channels.length == 1,
      );
      bus.dispatch(
        _ws('ChannelsServer', ActionType.delete, {
          'entityId': 2,
          'channelId': '11',
          'chatId': 91,
        }),
      );
      await removed;
      expect(repository.getByIdCached(11), isNull);

      await bloc.close();
      expect(repository.getCached(2), isEmpty);
      bus.dispose();
    },
  );

  test('CategoryChannelBloc merges websocket changes during loading', () async {
    final repository = _CategoryRepository()..release = Completer<void>();
    final bus = WsEventBus();
    final bloc = CategoryChannelBloc(repository, bus);
    final loading = bloc.stream.firstWhere(
      (state) => state is ChannelCategoriesLoading,
    );
    bloc.add(const GetChannelCategories(2));
    await loading;

    bus.dispatch(
      _ws('CategoryChannel', ActionType.create, {
        'serverId': 3,
        'category': {'id': 99, 'serverId': 3, 'name': 'Other'},
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.getByIdCached(99), isNull);

    final created = bloc.stream.firstWhere(
      (state) =>
          state is ChannelCategoriesLoaded &&
          state.categories.any((category) => category.id == 8),
    );
    bus.dispatch(
      _ws('CategoryChannel', ActionType.create, {
        'serverId': 2,
        'category': {'id': 8, 'name': 'New'},
      }),
    );
    await created;

    final merged = bloc.stream.firstWhere(
      (state) =>
          state is ChannelCategoriesLoaded && state.categories.length == 2,
    );
    repository.release!.complete();
    await merged;
    expect(repository.getByIdCached(8)?.name, 'New');

    final updated = bloc.stream.firstWhere(
      (state) =>
          state is ChannelCategoriesLoaded &&
          state.categories.any(
            (category) => category.id == 7 && category.name == 'Renamed',
          ),
    );
    bus.dispatch(
      _ws('CategoryChannel', ActionType.update, {
        'entityId': 2,
        'category': {'id': '7', 'name': 'Renamed'},
      }),
    );
    await updated;
    expect(repository.getByIdCached(7)?.serverId, 2);

    final removed = bloc.stream.firstWhere(
      (state) =>
          state is ChannelCategoriesLoaded && state.categories.length == 1,
    );
    bus.dispatch(
      _ws('CategoryChannel', ActionType.delete, {
        'serverId': 2,
        'categoryId': 8,
      }),
    );
    await removed;
    expect(repository.getByIdCached(8), isNull);

    await bloc.close();
    expect(repository.getCached(2), isEmpty);
    bus.dispose();
  });

  test(
    'ChannelServerBloc keeps websocket change over stale HTTP response',
    () async {
      final repository = _ChannelRepository()..release = Completer<void>();
      final bus = WsEventBus();
      final bloc = ChannelServerBloc(repository, bus);
      final loading = bloc.stream.firstWhere(
        (state) => state is ServerChannelsLoading,
      );
      bloc.add(const GetServerChannels(2));
      await loading;

      final created = bloc.stream.firstWhere(
        (state) =>
            state is ServerChannelsLoaded &&
            state.channels.any((channel) => channel.id == 11),
      );
      bus.dispatch(
        _ws('ChannelsServer', ActionType.create, {
          'serverId': 2,
          'channel': {'id': 11, 'chatName': 'New'},
        }),
      );
      await created;

      final merged = bloc.stream.firstWhere(
        (state) => state is ServerChannelsLoaded && state.channels.length == 2,
      );
      repository.release!.complete();
      await merged;
      expect(repository.getByIdCached(11)?.chatName, 'New');

      await bloc.close();
      bus.dispose();
    },
  );
}
