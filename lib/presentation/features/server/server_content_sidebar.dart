import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/call_data.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/repositories/category_channel_repository.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/category_channel/bloc/category_channel_bloc.dart';
import 'package:disalive/presentation/features/calls/bloc/call_participants_bloc.dart';
import 'package:disalive/presentation/features/calls/widgets/channel_call_participants.dart';
import 'package:disalive/presentation/features/category_channel/widgets/category_channel_item.dart';
import 'package:disalive/presentation/features/channel_server/bloc/channel_server_bloc.dart';
import 'package:disalive/presentation/features/channel_server/channel_form_screen.dart';
import 'package:disalive/presentation/features/channel_server/widgets/channel_server_item.dart';
import 'package:disalive/presentation/features/chat/read_status_actions.dart';
import 'package:disalive/presentation/features/invites/invite_server_screen.dart';
import 'package:disalive/presentation/features/invites/manage_server_invites_screen.dart';
import 'package:disalive/presentation/features/server/server_members_screen.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/role_members/role_members_screen.dart';
import 'package:disalive/presentation/features/server/server_action_permissions.dart';
import 'package:disalive/presentation/features/server/server_form_screen.dart';
import 'package:disalive/presentation/features/server/widgets/server_banner_image.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/app_text_input_sheet.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServerContentSidebar extends StatefulWidget {
  final Server server;
  final ValueChanged<ChannelServer>? onChannelTap;
  final VoidCallback? onInvite;
  final VoidCallback? onLeave;

  const ServerContentSidebar({
    super.key,
    required this.server,
    this.onChannelTap,
    this.onInvite,
    this.onLeave,
  });

  @override
  State<ServerContentSidebar> createState() => _ServerContentSidebarState();
}

class _ServerContentSidebarState extends State<ServerContentSidebar> {
  final Set<int> _collapsedCategories = {};
  final Set<int> _collapsedCalls = {};
  late final ChannelServerBloc _channelsBloc;
  late final CategoryChannelBloc _categoriesBloc;
  late final CallParticipantsBloc _callParticipantsBloc;

  int get _serverId => widget.server.id!;
  ServerActionPermissions get _rights =>
      ServerActionPermissions.fromServer(widget.server);

  @override
  void initState() {
    super.initState();
    _channelsBloc = ChannelServerBloc(
      sl<ChannelServerRepository>(),
      sl<WsEventBus>(),
    )..add(GetServerChannels(_serverId));
    _categoriesBloc = CategoryChannelBloc(
      sl<CategoryChannelRepository>(),
      sl<WsEventBus>(),
    )..add(GetChannelCategories(_serverId));
    _callParticipantsBloc = CallParticipantsBloc(sl<CallsRepository>())
      ..add(
        WatchCallParticipants(
          EntityKey(entityId: _serverId, entityType: EntityType.server),
        ),
      );
  }

  @override
  void didUpdateWidget(covariant ServerContentSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id) {
      _collapsedCategories.clear();
      _collapsedCalls.clear();
      _channelsBloc.add(GetServerChannels(_serverId));
      _categoriesBloc.add(GetChannelCategories(_serverId));
      _callParticipantsBloc.add(
        WatchCallParticipants(
          EntityKey(entityId: _serverId, entityType: EntityType.server),
        ),
      );
    }
  }

  @override
  void dispose() {
    _channelsBloc.close();
    _categoriesBloc.close();
    _callParticipantsBloc.close();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  void _invite() {
    if (widget.onInvite != null) {
      widget.onInvite!();
    } else {
      InviteServerScreen.open(context, server: widget.server);
    }
  }

  void _createChannel({int? categoryId}) {
    ChannelFormScreen.open(
      context,
      serverId: _serverId,
      serverName: widget.server.name ?? 'Сервер',
      channelsBloc: _channelsBloc,
      categoriesBloc: _categoriesBloc,
      initialCategoryId: categoryId,
    );
  }

  Future<void> _createCategory() async {
    final name = await AppTextInputSheet.show(
      context,
      title: 'Новая категория',
      actionLabel: 'Создать категорию',
      enableEmojis: true,
    );
    if (!mounted || name == null) return;
    final result = await sl<CategoryChannelRepository>().create(
      _serverId,
      name,
    );
    if (!mounted) return;
    result.fold(
      (failure) => _showMessage(failure.message),
      (category) => _categoriesBloc.add(
        ChannelCategoryUpserted(_serverId, category.toMap()),
      ),
    );
  }

  Future<void> _editServer() async {
    await ServerFormScreen.open(context, server: widget.server);
  }

  Future<void> _toggleMuted() async {
    final result = await sl<MembersRepository>().update(
      entityId: _serverId,
      entityType: EntityType.server,
      toggleMuted: true,
    );
    if (!mounted) return;
    result.fold((failure) => _showMessage(failure.message), (success) {
      if (success) {
        context.read<ServersBloc>().add(
          ServerUpserted({
            'id': _serverId,
            'muted': !widget.server.isServerMuted,
          }),
        );
      }
    });
  }

  Future<void> _leaveServer() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Покинуть сервер?',
      description: 'Вы больше не увидите его каналы.',
      confirmText: 'Покинуть',
      isDestructive: true,
      icon: CupertinoIcons.square_arrow_right,
    );
    if (confirmed != true || !mounted) return;
    final result = await sl<MembersRepository>().leave(
      _serverId,
      EntityType.server,
    );
    if (!mounted) return;
    result.fold((failure) => _showMessage(failure.message), (success) {
      if (success) {
        context.read<ServersBloc>().add(ServerRemoved(_serverId));
        widget.onLeave?.call();
      }
    });
  }

  void _editChannel(ChannelServer channel) {
    ChannelFormScreen.open(
      context,
      serverId: _serverId,
      serverName: widget.server.name ?? 'Сервер',
      channelsBloc: _channelsBloc,
      categoriesBloc: _categoriesBloc,
      channel: channel,
    );
  }

  Future<void> _deleteChannel(ChannelServer channel) async {
    if (channel.id == null) return;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Удалить канал?',
      description: 'Канал «${channel.chatName ?? 'Канал'}» будет удалён.',
      confirmText: 'Удалить',
      isDestructive: true,
      icon: CupertinoIcons.trash,
    );
    if (confirmed != true || !mounted) return;
    final result = await sl<ChannelServerRepository>().delete(channel.id!);
    if (!mounted) return;
    result.fold(
      (failure) => _showMessage(failure.message),
      (id) => _channelsBloc.add(ServerChannelRemoved(_serverId, id)),
    );
  }

  Future<void> _setMainChannel(ChannelServer channel) async {
    final channelId = channel.id;
    if (channelId == null) return;
    final result = await sl<ServerRepository>().update(
      _serverId,
      widget.server.name ?? 'Сервер',
      fkMainChannel: channelId,
    );
    if (!mounted) return;
    result.fold(
      (failure) => _showMessage(failure.message),
      (server) => context.read<ServersBloc>().add(
        ServerUpserted({...server.toMap(), 'fkMainChannel': channelId}),
      ),
    );
  }

  Future<void> _removeMainChannel() async {
    final result = await sl<ServerRepository>().update(
      _serverId,
      widget.server.name ?? 'Сервер',
      isSetNullMainChannel: true,
    );
    if (!mounted) return;
    result.fold(
      (failure) => _showMessage(failure.message),
      (server) => context.read<ServersBloc>().add(
        ServerUpserted({
          ...server.toMap(),
          'fkMainChannel': null,
          'mainChatId': 0,
        }),
      ),
    );
  }

  Future<void> _editCategory(CategoryChannel category) async {
    final name = await AppTextInputSheet.show(
      context,
      title: 'Переименовать категорию',
      initialValue: category.name ?? '',
      enableEmojis: true,
    );
    if (!mounted || name == null || category.id == null) return;
    final result = await sl<CategoryChannelRepository>().update(
      category.id!,
      name,
    );
    if (!mounted) return;
    result.fold(
      (failure) => _showMessage(failure.message),
      (updated) => _categoriesBloc.add(
        ChannelCategoryUpserted(_serverId, updated.toMap()),
      ),
    );
  }

  Future<void> _deleteCategory(CategoryChannel category) async {
    if (category.id == null) return;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Удалить категорию?',
      description: 'Категория «${category.name ?? 'Категория'}» будет удалена.',
      confirmText: 'Удалить',
      isDestructive: true,
      icon: CupertinoIcons.trash,
    );
    if (confirmed != true || !mounted) return;
    final result = await sl<CategoryChannelRepository>().delete(category.id!);
    if (!mounted) return;
    result.fold((failure) => _showMessage(failure.message), (success) {
      if (success) {
        _categoriesBloc.add(ChannelCategoryRemoved(_serverId, category.id!));
        _channelsBloc.add(GetServerChannels(_serverId));
      }
    });
  }

  void _showChannelActions(ChannelServer channel) {
    final actions = <ActionItem>[
      if (channel.newMessagesCount > 0)
        ActionItem(
          icon: CupertinoIcons.checkmark_circle,
          label: 'Прочитать канал',
          onTap: () => ReadStatusActions.markChannel(
            context,
            _serverId,
            channel,
            refreshChannels: () =>
                _channelsBloc.add(GetServerChannels(_serverId)),
          ),
        ),
      if (_rights.canManageServer &&
          channel.id != null &&
          widget.server.fkMainChannel != channel.id)
        ActionItem(
          icon: CupertinoIcons.star_fill,
          label: 'Сделать главным каналом',
          onTap: () => _setMainChannel(channel),
        ),
      if (_rights.canManageServer &&
          channel.id != null &&
          widget.server.fkMainChannel == channel.id)
        ActionItem(
          icon: CupertinoIcons.star_slash,
          label: 'Убрать основной канал',
          onTap: _removeMainChannel,
        ),
      if (_rights.canManageChannels) ...[
        ActionItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать канал',
          onTap: () => _editChannel(channel),
        ),
        ActionItem(
          icon: CupertinoIcons.delete,
          label: 'Удалить канал',
          isDestructive: true,
          onTap: () => _deleteChannel(channel),
        ),
      ],
    ];
    if (actions.isEmpty) return;
    ActionBottomSheet.show(context, title: channel.chatName, actions: actions);
  }

  void _showCategoryActions(CategoryChannel category) {
    if (!_rights.canManageCategories) return;
    ActionBottomSheet.show(
      context,
      title: category.name,
      actions: [
        ActionItem(
          icon: CupertinoIcons.pencil,
          label: 'Переименовать категорию',
          onTap: () => _editCategory(category),
        ),
        ActionItem(
          icon: CupertinoIcons.delete,
          label: 'Удалить категорию',
          isDestructive: true,
          onTap: () => _deleteCategory(category),
        ),
      ],
    );
  }

  void _showServerActions() {
    final rights = _rights;
    ActionBottomSheet.show(
      context,
      title: widget.server.name,
      actions: [
        if ((widget.server.newMessagesCount ?? 0) > 0)
          ActionItem(
            icon: CupertinoIcons.checkmark_circle,
            label: 'Пометить как прочитанное',
            onTap: () => ReadStatusActions.markServer(
              context,
              widget.server,
              refreshChannels: () =>
                  _channelsBloc.add(GetServerChannels(_serverId)),
            ),
          ),
        if (rights.canInvite)
          ActionItem(
            icon: CupertinoIcons.person_add,
            label: 'Пригласить на сервер',
            onTap: _invite,
          ),
        ActionItem(
          icon: widget.server.isServerMuted
              ? CupertinoIcons.bell_fill
              : CupertinoIcons.bell_slash_fill,
          label: widget.server.isServerMuted
              ? 'Включить уведомления'
              : 'Выключить уведомления',
          onTap: _toggleMuted,
        ),
        if (rights.canManageServer)
          ActionItem(
            icon: CupertinoIcons.pencil,
            label: 'Редактировать сервер',
            onTap: _editServer,
          ),
        if (rights.canManageRoles)
          ActionItem(
            icon: CupertinoIcons.shield_lefthalf_fill,
            label: 'Управление ролями',
            onTap: () => RoleMembersScreen.open(
              context,
              entityId: _serverId,
              entityType: EntityType.server,
              entityName: widget.server.name ?? 'Сервер',
            ),
          ),
        if (rights.canManageChannels)
          ActionItem(
            icon: CupertinoIcons.add_circled,
            label: 'Создать канал',
            onTap: _createChannel,
          ),
        if (rights.canManageCategories)
          ActionItem(
            icon: CupertinoIcons.folder_badge_plus,
            label: 'Создать категорию',
            onTap: _createCategory,
          ),
        ActionItem(
          icon: CupertinoIcons.square_arrow_right,
          label: 'Покинуть сервер',
          isDestructive: true,
          onTap: _leaveServer,
        ),
      ],
    );
  }

  void _showSettingsActions() {
    final rights = _rights;
    if (!rights.canOpenSettings) return;
    ActionBottomSheet.show(
      context,
      title: widget.server.name,
      actions: [
        if (rights.canManageServer)
          ActionItem(
            icon: CupertinoIcons.gear,
            label: 'Управлять сервером',
            onTap: _editServer,
          ),
        if (rights.canManageRoles)
          ActionItem(
            icon: CupertinoIcons.shield_lefthalf_fill,
            label: 'Управлять ролями',
            onTap: () => RoleMembersScreen.open(
              context,
              entityId: _serverId,
              entityType: EntityType.server,
              entityName: widget.server.name ?? 'Сервер',
            ),
          ),
        if (rights.canManageMembers)
          ActionItem(
            icon: CupertinoIcons.person_2,
            label: 'Управлять участниками',
            onTap: () =>
                ServerMembersScreen.open(context, server: widget.server),
          ),
        if (rights.canManageInvites)
          ActionItem(
            icon: CupertinoIcons.link,
            label: 'Управлять приглашениями',
            onTap: () =>
                ManageServerInvitesScreen.open(context, server: widget.server),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ChannelServerBloc>.value(value: _channelsBloc),
        BlocProvider<CategoryChannelBloc>.value(value: _categoriesBloc),
      ],
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(28)),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(28)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.lightGrey.withValues(alpha: 0.72),
                    AppColors.lightGrey.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Container(
                    height: 1,
                    color: AppColors.white.withValues(alpha: 0.10),
                  ),
                  Expanded(child: _buildStructure()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final banner = widget.server.pathBanner;
    final hasBanner = banner != null && banner.isNotEmpty;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(16, hasBanner ? 8 : 18, 16, hasBanner ? 8 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            key: const ValueKey('server_header'),
            behavior: HitTestBehavior.opaque,
            onTap: _showServerActions,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.server.name ?? 'Сервер',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.highTextStyle.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 15,
                  color: AppColors.greyple,
                ),
              ],
            ),
          ),
          SizedBox(height: hasBanner ? 8 : 14),
          Row(
            children: [
              if (_rights.canOpenSettings) ...[
                GlassButton(
                  key: const ValueKey('server_settings'),
                  borderRadius: 32,
                  padding: const EdgeInsets.all(11),
                  onTap: _showSettingsActions,
                  child: Icon(
                    CupertinoIcons.gear,
                    color: AppColors.white.withValues(alpha: 0.75),
                    size: 18,
                  ),
                ),
              ],
              if (_rights.canInvite) ...[
                if (_rights.canOpenSettings) const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    key: const ValueKey('invite_server'),
                    borderRadius: 32,
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 14,
                    ),
                    onTap: _invite,
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_add_solid,
                          color: AppColors.white.withValues(alpha: 0.75),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Пригласить',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    if (!hasBanner) return content;

    return SizedBox(
      height: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ServerBannerImage(path: banner),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35, 1],
                colors: [
                  CupertinoColors.transparent,
                  AppColors.mainBackground.withValues(alpha: 0.38),
                  AppColors.mainBackground.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: content),
        ],
      ),
    );
  }

  Widget _buildStructure() {
    return BlocBuilder<CategoryChannelBloc, CategoryChannelState>(
      builder: (context, categoryState) {
        return BlocBuilder<ChannelServerBloc, ChannelServerState>(
          builder: (context, channelState) {
            if (categoryState is ChannelCategoriesLoading ||
                categoryState is CategoryChannelInitial ||
                channelState is ServerChannelsLoading ||
                channelState is ChannelServerInitial) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (categoryState is ChannelCategoriesFailure ||
                channelState is ServerChannelsFailure) {
              return Center(
                child: CupertinoButton(
                  onPressed: () {
                    _categoriesBloc.add(GetChannelCategories(_serverId));
                    _channelsBloc.add(GetServerChannels(_serverId));
                  },
                  child: const Text('Повторить загрузку'),
                ),
              );
            }
            if (categoryState is! ChannelCategoriesLoaded ||
                channelState is! ServerChannelsLoaded) {
              return const SizedBox.shrink();
            }

            final categories = categoryState.categories;
            final channels = channelState.channels;
            if (categories.isEmpty && channels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.number,
                      size: 42,
                      color: AppColors.greyple,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Каналов пока нет',
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.greyple,
                      ),
                    ),
                    if (_rights.canManageChannels) ...[
                      const SizedBox(height: 14),
                      CupertinoButton.filled(
                        key: const ValueKey('empty_create_channel'),
                        onPressed: _createChannel,
                        child: const Text('Создать канал'),
                      ),
                    ],
                  ],
                ),
              );
            }

            final uncategorized = channels
                .where(
                  (channel) =>
                      channel.categoryId == null ||
                      !categories.any(
                        (category) => category.id == channel.categoryId,
                      ),
                )
                .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(7, 8, 7, 120),
              physics: const BouncingScrollPhysics(),
              children: [
                if (uncategorized.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                    child: Text(
                      'КАНАЛЫ',
                      style: AppText.lowTextStyle.copyWith(
                        color: AppColors.greyple,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  for (final channel in uncategorized) _channelItem(channel),
                ],
                for (final category in categories) ...[
                  CategoryChannelItem(
                    key: ValueKey('category_${category.id}'),
                    category: category,
                    isCollapsed: _collapsedCategories.contains(category.id),
                    onTap: () => setState(() {
                      if (!_collapsedCategories.add(category.id!)) {
                        _collapsedCategories.remove(category.id);
                      }
                    }),
                    onLongPress: () => _showCategoryActions(category),
                    onAddChannel: _rights.canManageChannels
                        ? () => _createChannel(categoryId: category.id)
                        : null,
                  ),
                  if (!_collapsedCategories.contains(category.id))
                    for (final channel in channels.where(
                      (channel) => channel.categoryId == category.id,
                    ))
                      _channelItem(channel),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _channelItem(ChannelServer channel) {
    return BlocBuilder<CallParticipantsBloc, CallParticipantsState>(
      bloc: _callParticipantsBloc,
      builder: (context, state) {
        final chatId = channel.chatId;
        final participants = chatId == null
            ? const <CallParticipant>[]
            : state.participants.forChat(chatId);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChannelServerItem(
              key: ValueKey('channel_${channel.id}'),
              channel: channel,
              participantCount: participants.length,
              onTap: () => widget.onChannelTap?.call(channel),
              onLongPress: () => _showChannelActions(channel),
            ),
            if (chatId != null && participants.isNotEmpty)
              ChannelCallParticipants(
                key: ValueKey('channel_call_$chatId'),
                participants: participants,
                maxParticipants: channel.maxParticipants,
                isCollapsed: _collapsedCalls.contains(chatId),
                onToggle: () => setState(() {
                  if (!_collapsedCalls.add(chatId)) {
                    _collapsedCalls.remove(chatId);
                  }
                }),
              ),
          ],
        );
      },
    );
  }
}
