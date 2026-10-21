import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';

class ServerDiscoverySidebar extends StatefulWidget {
  const ServerDiscoverySidebar({
    super.key,
    required this.onOpenServer,
    required this.onJoinedServer,
    required this.gridView,
  });

  final ValueChanged<Server> onOpenServer;
  final ValueChanged<Server> onJoinedServer;
  final bool gridView;

  @override
  State<ServerDiscoverySidebar> createState() => _ServerDiscoverySidebarState();
}

class _ServerDiscoverySidebarState extends State<ServerDiscoverySidebar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  ServerType? _category;
  List<Server> _servers = const [];
  final Set<int> _joining = {};
  bool _loading = true;
  Failure? _error;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _requestVersion++;
    _searchDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load({bool showLoading = true}) async {
    final version = ++_requestVersion;
    setState(() {
      if (showLoading) _loading = true;
      _error = null;
    });
    final result = await sl<ServerRepository>().get(
      isPublic: true,
      category: _category,
      query: _searchController.text.trim(),
    );
    if (!mounted || version != _requestVersion) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure;
      }),
      (servers) => setState(() {
        _loading = false;
        _servers = servers;
      }),
    );
  }

  Future<void> _join(Server server) async {
    final id = server.id;
    if (id == null || !_joining.add(id)) return;
    setState(() {});
    final result = await sl<MembersRepository>().create(id, EntityType.server);
    if (!mounted) return;
    _joining.remove(id);
    result.fold((failure) {
      setState(() {});
      CustomToast.open(context: context, message: failure.message);
    }, widget.onJoinedServer);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28)),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lightGrey.withValues(alpha: 0.72),
            AppColors.lightGrey.withValues(alpha: 0.55),
          ],
        ),
      ),
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Container(height: 1, color: AppColors.white.withValues(alpha: 0.10)),
          Expanded(child: _serverList()),
        ],
      ),
    ),
  );

  Widget _header() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 20, 0, 16),
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppColors.blurple, AppColors.darkHighlight],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Text(
            'Найдите сообщества себе по душе в Disalive',
            style: AppText.highTextStyle.copyWith(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(right: 18, bottom: 14),
          child: CupertinoTextField(
            key: const ValueKey('public_server_search'),
            controller: _searchController,
            onChanged: _onSearchChanged,
            placeholder: 'Поиск серверов',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(CupertinoIcons.search, size: 18),
            ),
            clearButtonMode: OverlayVisibilityMode.editing,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            style: TextStyle(color: AppColors.white),
            placeholderStyle: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
            decoration: BoxDecoration(
              color: AppColors.mainBackground.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _categoryChip(null, 'Все'),
              for (final type in ServerType.values.where(
                (type) => type != ServerType.none,
              ))
                _categoryChip(type, type.label),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _serverList() => LayoutBuilder(
    builder: (context, constraints) {
      const padding = 12.0;
      const spacing = 10.0;
      final availableWidth = constraints.maxWidth - padding * 2;
      final maxColumns = ((availableWidth + spacing) / (100 + spacing))
          .floor()
          .clamp(1, 4);
      final columns = widget.gridView ? maxColumns.clamp(1, 2) : 1;
      final compact = columns > 1;
      Widget cardAt(int index) {
        final server = _servers[index];
        return _DiscoveryServerCard(
          server: server,
          compact: compact,
          joining: _joining.contains(server.id),
          onOpen: () => widget.onOpenServer(server),
          onJoin: () => _join(server),
        );
      }

      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => _load(showLoading: false),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorStateView(failure: _error!, onRetry: _load),
            )
          else if (_servers.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Публичные серверы не найдены',
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.greyple,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(padding, 14, padding, 100),
              sliver: compact
                  ? SliverList.builder(
                      key: ValueKey('public_servers_columns_$columns'),
                      itemCount: (_servers.length + columns - 1) ~/ columns,
                      itemBuilder: (context, rowIndex) => Padding(
                        padding: const EdgeInsets.only(bottom: spacing),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var column = 0; column < columns; column++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: column == columns - 1 ? 0 : spacing,
                                  ),
                                  child:
                                      rowIndex * columns + column <
                                          _servers.length
                                      ? cardAt(rowIndex * columns + column)
                                      : const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : SliverGrid.builder(
                      key: ValueKey('public_servers_columns_$columns'),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 184,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemCount: _servers.length,
                      itemBuilder: (context, index) => cardAt(index),
                    ),
            ),
        ],
      );
    },
  );

  Widget _categoryChip(ServerType? category, String label) {
    final selected = category == _category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CupertinoButton(
        key: ValueKey('public_category_${category?.value ?? 'all'}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        minimumSize: Size.zero,
        color: selected
            ? AppColors.white
            : AppColors.mainBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        onPressed: () {
          if (_category == category) return;
          _category = category;
          _load();
        },
        child: Text(
          label,
          style: AppText.lowTextStyle.copyWith(
            color: selected ? AppColors.dark : AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _DiscoveryServerCard extends StatelessWidget {
  const _DiscoveryServerCard({
    required this.server,
    required this.compact,
    required this.joining,
    required this.onOpen,
    required this.onJoin,
  });

  final Server server;
  final bool compact;
  final bool joining;
  final VoidCallback onOpen;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('public_server_${server.id}'),
    padding: compact
        ? const EdgeInsets.fromLTRB(10, 10, 10, 8)
        : const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.mainBackground.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
    ),
    child: Column(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact) ...[
          Row(
            children: [
              _avatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _compactCount(
                      CupertinoColors.activeGreen,
                      server.onlineMemberCount ?? 0,
                    ),
                    const SizedBox(height: 4),
                    _compactCount(AppColors.greyple, server.memberCount ?? 0),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _name(),
          const SizedBox(height: 8),
          _actionButton(),
        ] else ...[
          Row(
            children: [
              _avatar(),
              const SizedBox(width: 12),
              Expanded(child: _name()),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _count(
                CupertinoColors.activeGreen,
                '${server.onlineMemberCount ?? 0} в сети',
              ),
              _count(
                AppColors.greyple,
                '${server.memberCount ?? 0} участников',
              ),
            ],
          ),
          const Spacer(),
          _actionButton(),
        ],
      ],
    ),
  );

  Widget _actionButton() {
    final join = server.memberId == null;
    final label = join ? 'Присоединиться' : 'Открыть сервер';
    return Semantics(
      label: compact ? label : null,
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          key: ValueKey('public_server_action_${server.id}'),
          padding: EdgeInsets.symmetric(vertical: compact ? 5 : 10),
          minimumSize: compact ? const Size(0, 34) : null,
          onPressed: joining || server.id == null
              ? null
              : join
              ? onJoin
              : onOpen,
          child: joining
              ? const CupertinoActivityIndicator()
              : compact
              ? Icon(
                  join
                      ? CupertinoIcons.person_add_solid
                      : CupertinoIcons.arrow_right,
                  size: 20,
                )
              : Text(label),
        ),
      ),
    );
  }

  Widget _compactCount(Color color, int count) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          '$count',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.lowTextStyle.copyWith(
            color: AppColors.greyple,
            fontSize: 11,
          ),
        ),
      ),
    ],
  );

  Widget _name() => Text(
    server.name?.isNotEmpty == true ? server.name! : 'Неизвестный сервер',
    maxLines: compact ? 1 : 2,
    overflow: TextOverflow.ellipsis,
    style: AppText.highTextStyle.copyWith(
      color: AppColors.white,
      fontSize: compact ? 15 : null,
    ),
  );

  Widget _avatar() {
    final name = server.name?.trim() ?? '';
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final path = server.pathAvatar;
    String? url;
    if (path != null && path.isNotEmpty) {
      final transformed = Domain.transformUrl(path);
      final uri = Uri.tryParse(transformed);
      if (uri != null) {
        url = uri.hasScheme
            ? transformed
            : Uri.parse(Domain.imageDomain).resolve(transformed).toString();
      }
    }
    final size = compact ? 42.0 : 52.0;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.blurple,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.onBlurple,
          fontSize: compact ? 19 : 23,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: url == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }

  Widget _count(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.lowTextStyle.copyWith(
            color: AppColors.greyple,
            fontSize: compact ? 11 : null,
          ),
        ),
      ),
    ],
  );
}
