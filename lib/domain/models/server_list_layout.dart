import 'package:equatable/equatable.dart';

class ServerListItem extends Equatable {
  const ServerListItem.server(this.serverId)
    : folderId = null,
      name = null,
      servers = const [];

  const ServerListItem.folder({
    this.folderId,
    required this.name,
    this.servers = const [],
  }) : serverId = null;

  final int? serverId;
  final int? folderId;
  final String? name;
  final List<int> servers;

  bool get isFolder => serverId == null;

  factory ServerListItem.fromMap(Map<String, dynamic> map) {
    if (map['type'] == 'folder') {
      return ServerListItem.folder(
        folderId: _int(map['folderId']),
        name: (map['name'] ?? '').toString(),
        servers: (map['servers'] as List? ?? const [])
            .map(_int)
            .whereType<int>()
            .toList(),
      );
    }
    final id = _int(map['serverId']);
    if (id == null) throw const FormatException('Invalid server list item');
    return ServerListItem.server(id);
  }

  Map<String, dynamic> toMap() => isFolder
      ? {
          'type': 'folder',
          if (folderId != null) 'folderId': folderId,
          'name': name,
          'servers': servers,
        }
      : {'type': 'server', 'serverId': serverId};

  ServerListItem copyFolder({String? name, List<int>? servers}) =>
      ServerListItem.folder(
        folderId: folderId,
        name: name ?? this.name ?? '',
        servers: servers ?? this.servers,
      );

  @override
  List<Object?> get props => [serverId, folderId, name, servers];
}

class ServerListLayout extends Equatable {
  const ServerListLayout(this.items);
  final List<ServerListItem> items;

  factory ServerListLayout.fromMap(Map<String, dynamic> map) =>
      ServerListLayout(
        (map['items'] as List? ?? const [])
            .map(
              (item) => ServerListItem.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );

  Map<String, dynamic> toMap() => {
    'items': items.map((item) => item.toMap()).toList(),
  };

  /// Retains the API order and folders while including every current membership once.
  ServerListLayout reconcile(Iterable<int> serverIds) {
    final valid = serverIds.toSet();
    final seen = <int>{};
    final result = <ServerListItem>[];
    for (final item in items) {
      if (item.isFolder) {
        result.add(
          item.copyFolder(
            servers: item.servers
                .where((id) => valid.contains(id) && seen.add(id))
                .toList(),
          ),
        );
      } else if (valid.contains(item.serverId) && seen.add(item.serverId!)) {
        result.add(item);
      }
    }
    for (final id in serverIds) {
      if (seen.add(id)) result.add(ServerListItem.server(id));
    }
    return ServerListLayout(result);
  }

  @override
  List<Object?> get props => [items];
}

int? _int(Object? value) => value is int ? value : int.tryParse('$value');
