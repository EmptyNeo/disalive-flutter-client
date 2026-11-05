import 'package:bloc/bloc.dart';
import 'package:disalive/domain/models/server_list_layout.dart';
import 'package:disalive/domain/repositories/server_list_repository.dart';
import 'package:equatable/equatable.dart';

class ServerListState extends Equatable {
  const ServerListState({
    required this.layout,
    this.loaded = false,
    this.saving = false,
    this.error,
  });
  final ServerListLayout layout;
  final bool loaded;
  final bool saving;
  final String? error;

  @override
  List<Object?> get props => [layout, loaded, saving, error];
}

class ServerListCubit extends Cubit<ServerListState> {
  ServerListCubit(this._repository)
    : super(const ServerListState(layout: ServerListLayout([])));
  final ServerListRepository _repository;
  List<int> _serverIds = const [];
  bool _loading = false;

  void syncServers(Iterable<int> ids) {
    _serverIds = ids.toSet().toList();
    if (!state.loaded && !_loading) {
      load();
    } else if (state.loaded) {
      final layout = state.layout.reconcile(_serverIds);
      if (layout != state.layout) {
        emit(
          ServerListState(
            layout: layout,
            loaded: true,
            saving: state.saving,
            error: state.error,
          ),
        );
      }
    }
  }

  Future<void> load() async {
    if (_loading || state.saving) return;
    _loading = true;
    final result = await _repository.getLayout();
    _loading = false;
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        ServerListState(
          layout: state.layout.reconcile(_serverIds),
          loaded: true,
          error: failure.message,
        ),
      ),
      (layout) => emit(
        ServerListState(layout: layout.reconcile(_serverIds), loaded: true),
      ),
    );
  }

  Future<void> _save(ServerListLayout layout) async {
    if (state.saving) return;
    final previous = state.layout;
    emit(
      ServerListState(
        layout: layout.reconcile(_serverIds),
        loaded: true,
        saving: true,
      ),
    );
    final result = await _repository.saveLayout(state.layout);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        ServerListState(
          layout: previous.reconcile(_serverIds),
          loaded: true,
          error: failure.message,
        ),
      ),
      (saved) => emit(
        ServerListState(layout: saved.reconcile(_serverIds), loaded: true),
      ),
    );
  }

  Future<void> createFolder(String name) async {
    if (state.saving) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.runes.length > 50) return;
    await _save(
      ServerListLayout([
        ...state.layout.items,
        ServerListItem.folder(name: trimmed),
      ]),
    );
  }

  Future<void> renameFolder(int folderId, String name) async {
    if (state.saving) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.runes.length > 50) return;
    await _save(
      ServerListLayout([
        for (final item in state.layout.items)
          item.isFolder && item.folderId == folderId
              ? item.copyFolder(name: trimmed)
              : item,
      ]),
    );
  }

  Future<void> deleteFolder(int folderId) async {
    if (state.saving) return;
    final items = <ServerListItem>[];
    for (final item in state.layout.items) {
      if (item.isFolder && item.folderId == folderId) {
        items.addAll(item.servers.map(ServerListItem.server));
      } else {
        items.add(item);
      }
    }
    await _save(ServerListLayout(items));
  }

  Future<void> moveServer(int serverId, {int? folderId}) async {
    if (state.saving) return;
    final items = <ServerListItem>[];
    var foundFolder = false;
    for (final item in state.layout.items) {
      if (item.isFolder) {
        final servers = item.servers.where((id) => id != serverId).toList();
        if (item.folderId == folderId) {
          foundFolder = true;
          servers.add(serverId);
        }
        items.add(item.copyFolder(servers: servers));
      } else if (item.serverId != serverId) {
        items.add(item);
      }
    }
    if (folderId == null || !foundFolder) {
      items.add(ServerListItem.server(serverId));
    }
    await _save(ServerListLayout(items));
  }

  Future<void> reorderRoot(int oldIndex, int newIndex) async {
    if (state.saving) return;
    final items = [...state.layout.items];
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex > oldIndex) newIndex--;
    items.insert(newIndex.clamp(0, items.length - 1), items.removeAt(oldIndex));
    await _save(ServerListLayout(items));
  }

  Future<void> reorderFolder(int folderId, int oldIndex, int newIndex) async {
    if (state.saving) return;
    final items = [...state.layout.items];
    final index = items.indexWhere(
      (item) => item.isFolder && item.folderId == folderId,
    );
    if (index < 0) return;
    final servers = [...items[index].servers];
    if (oldIndex < 0 || oldIndex >= servers.length) return;
    if (newIndex > oldIndex) newIndex--;
    servers.insert(
      newIndex.clamp(0, servers.length - 1),
      servers.removeAt(oldIndex),
    );
    items[index] = items[index].copyFolder(servers: servers);
    await _save(ServerListLayout(items));
  }
}
