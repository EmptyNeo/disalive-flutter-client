import 'dart:async';
import 'dart:io';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/repositories/local_chat_state_repository.dart';
import 'package:disalive/domain/enums/user_response_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/app_update_repository.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/gifs_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/media_stats_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/preferred_reactions_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/repositories/requests_repository.dart';
import 'package:disalive/domain/repositories/session_repository.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';
import 'package:disalive/domain/repositories/stickers_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/repositories/user_stickers_pack_repository.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:disalive/domain/services/system_insets_service.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:disalive/presentation/bloc/session/session_bloc.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/calls/bloc/call_bloc.dart';
import 'package:disalive/presentation/features/calls/call_screen.dart';
import 'package:disalive/presentation/features/calls/incoming_call_dialog.dart';
import 'package:disalive/presentation/features/calls/call_pip_overlay.dart';
import 'package:disalive/presentation/features/chat_server/bloc/chat_server_bloc.dart';
import 'package:disalive/presentation/features/gifs/bloc/gif_bloc.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/home/screens/create_chat_screen.dart';
import 'package:disalive/presentation/features/home/bottom_system_inset_tracker.dart';
import 'package:disalive/presentation/features/updates/app_update_sheet.dart';
import 'package:disalive/presentation/features/home/widgets/chats_view.dart';
import 'package:disalive/presentation/features/components/bottom_menu.dart';
import 'package:disalive/presentation/features/login.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/profile/personal_profile_screen.dart';
import 'package:disalive/presentation/features/reactions/bloc/preferred_reactions_bloc.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/settings/settings_screen.dart';
import 'package:disalive/presentation/features/home/widgets/supportive/keep_alive_page.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

// 🎯 1. ДОБАВЛЯЕМ ИМПОРТЫ ТЕМЫ
import 'package:disalive/presentation/bloc/theme/theme_cubit.dart';
import 'package:disalive/presentation/bloc/theme/theme_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static BuildContext? scopeContext;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late PageController _pageController;
  int personalUnredCount = 0;
  bool isReconnect = false;
  bool _isDiscoveringServers = false;
  bool _discoveryGridView = false;
  bool _incomingCallDialogOpen = false;
  bool _checkedForUpdates = false;
  final _bottomSystemInset = BottomSystemInsetTracker();
  bool _bottomInsetRefreshScheduled = false;
  int _bottomInsetRequestRevision = 0;

  Future<void> _checkForUpdates() async {
    if (_checkedForUpdates || !Platform.isAndroid) return;
    _checkedForUpdates = true;
    try {
      final package = await PackageInfo.fromPlatform();
      final currentVersion = package.version.split('.').length >= 4
          ? package.version
          : '${package.version}.${package.buildNumber}';
      final result = await sl<AppUpdateRepository>().checkAndroid(currentVersion);
      if (!mounted) return;
      result.fold(
        (_) {},
        (update) {
          if (update.isUpdateAvailable && update.downloadUrl.isNotEmpty) {
            unawaited(showAppUpdateSheet(context, update));
          }
        },
      );
    } catch (_) {
      // A failed background check must not interrupt the home screen.
    }
  }

  Future<void> _showIncomingCall(
    BuildContext context,
    IncomingCall call,
  ) async {
    if (_incomingCallDialogOpen) return;
    _incomingCallDialogOpen = true;
    final accepted = await showIncomingCallDialog(context, call);
    _incomingCallDialogOpen = false;
    if (!mounted || !context.mounted) return;
    context.read<CallBloc>().add(const DismissIncomingCall());
    if (!accepted) return;
    final chat = sl<ChatRepository>()
        .getCached()
        .where((item) => item.id == call.chatId)
        .firstOrNull;
    unawaited(
      CallScreen.open(
        context,
        chatId: call.chatId,
        entityKey: EntityKey(
          entityId: call.chatId,
          entityType: EntityType.chat,
        ),
        title: chat?.name ?? call.displayName,
        lastIdMessage: chat?.idLastMessage,
        announceCall: false,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    CallScreen.exitRevision.addListener(_onCallScreenExited);
    WidgetsBinding.instance.addObserver(this);
    _scheduleBottomInsetRefresh();
  }

  void _onCallScreenExited() {
    _scheduleBottomInsetRefresh();
  }

  @override
  void didChangeMetrics() {
    _scheduleBottomInsetRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleBottomInsetRefresh();
  }

  void _scheduleBottomInsetRefresh() {
    if (_bottomInsetRefreshScheduled) return;
    _bottomInsetRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bottomInsetRefreshScheduled = false;
      if (mounted) unawaited(_refreshBottomInset());
    });
  }

  Future<void> _refreshBottomInset() async {
    final requestRevision = ++_bottomInsetRequestRevision;
    final nativeInset = await SystemInsetsService.navigationBarBottom();
    if (!mounted || requestRevision != _bottomInsetRequestRevision) return;
    if (_bottomSystemInset.updateFromPlatform(nativeInset)) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CallScreen.exitRevision.removeListener(_onCallScreenExited);
    HomeScreen.scopeContext = null;
    CallPipOverlay.dispose();
    if (sl.isRegistered<MediaStatsRepository>()) {
      sl<MediaStatsRepository>().clear();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CallBloc>(
          lazy: false,
          create: (_) => CallBloc(
            sl<CallsRepository>(),
            sl<ChatServerRepository>(),
            sl<WsEventBus>(),
            sl<ChatRepository>(),
            sl<UserRepository>(),
          ),
        ),
        BlocProvider<ChatServerBloc>(
          lazy: false,
          create: (_) =>
              ChatServerBloc(sl<ChatServerRepository>())
                ..add(ConnectToChatServer()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(
            sl<UserRepository>(),
            sl<AuthBloc>(),
            sl<WsEventBus>(),
          )..add(GetProfile(userResponseType: UserResponseType.user)),
        ),
        BlocProvider<ChatBloc>(
          create: (_) =>
              ChatBloc(sl<ChatRepository>(), sl<WsEventBus>())..add(GetChats()),
        ),
        BlocProvider<ServersBloc>(
          lazy: false,
          create: (_) => sl<ServersBloc>()..add(const GetServers()),
        ),
        BlocProvider<RequestsBloc>(
          create: (_) =>
              RequestsBloc(sl<RequestsRepository>(), sl<WsEventBus>())
                ..add(GetRequests(true)),
        ),
        BlocProvider<MessageBloc>(
          create: (_) => MessageBloc(
            sl<MessageRepository>(),
            sl<ReactionsRepository>(),
            sl<ChatRepository>(),
            sl<WsEventBus>(),
          ),
        ),
        BlocProvider<InvitesBloc>(create: (_) => sl<InvitesBloc>()),
        BlocProvider<MediaStatsBloc>(
          lazy: false,
          create: (_) => sl<MediaStatsBloc>()..add(const LoadMediaStats()),
        ),
        BlocProvider<MembersBloc>(
          create: (_) => MembersBloc(sl<MembersRepository>(), sl<WsEventBus>()),
        ),
        BlocProvider<SessionBloc>(
          create: (_) => SessionBloc(
            sl<UserRepository>(),
            sl<SessionRepository>(),
            sl<SecureStorageService>(),
            sl<WsEventBus>(),
            sl<LocalChatStateRepository>(),
          ),
        ),
        BlocProvider<GifBloc>(create: (_) => GifBloc(sl<GifsRepository>())),
        BlocProvider<StickersPackBloc>(
          create: (_) => StickersPackBloc(
            sl<StickerPackRepository>(),
            sl<UserStickersPackRepository>(),
            sl<StickersRepository>(),
          ),
        ),
        BlocProvider<PreferredReactionsBloc>(
          create: (_) =>
              PreferredReactionsBloc(sl<PreferredReactionsRepository>()),
        ),
      ],
      child: Builder(
        builder: (scopeContext) {
          HomeScreen.scopeContext = scopeContext;
          return MultiBlocListener(
            listeners: [
              BlocListener<ChatServerBloc, ChatServerState>(
                listener: (context, state) {
                  final shouldShowReconnect = state is! ChatServerConnected;

                  if (isReconnect != shouldShowReconnect) {
                    setState(() {
                      isReconnect = shouldShowReconnect;
                    });
                  }

                  if (state is ChatServerConnected) {
                    context.read<CallBloc>().setupListeners();
                    context.read<ChatBloc>().setupListeners();
                    context.read<MessageBloc>().setupListeners();
                    context.read<MembersBloc>().setupListeners();
                    context.read<SessionBloc>().setupListeners();
                    context.read<ProfileBloc>().setupListeners();
                  }
                },
              ),
              BlocListener<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is ChatLoaded) {
                    setState(() {
                      personalUnredCount = state.unreadCount;
                    });
                  }
                },
              ),
              BlocListener<CallBloc, CallState>(
                listenWhen: (previous, current) =>
                    previous.incomingCall != current.incomingCall &&
                    current.incomingCall != null,
                listener: (context, state) {
                  unawaited(_showIncomingCall(context, state.incomingCall!));
                },
              ),
              BlocListener<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state is AuthLogout) {
                    context.read<CallBloc>().add(const LeaveCall());
                    LoginScreen.routeToMe(context);
                  }
                },
              ),
              BlocListener<SessionBloc, SessionState>(
                listener: (context, state) {
                  if (state is SessionLoggedOut) {
                    context.read<CallBloc>().add(const LeaveCall());
                    LoginScreen.routeToMe(context);
                  }
                },
              ),
            ],
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoading) {
                  return CupertinoPageScaffold(
                    backgroundColor: AppColors.mainBackground,
                    child: const Center(
                      child: CupertinoActivityIndicator(radius: 12),
                    ),
                  );
                }

                if (state is ProfileLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) unawaited(_checkForUpdates());
                  });
                  // 🎯 2. ОБЕРТЫВАЕМ UI В BlocBuilder<ThemeCubit>
                  // Это заставит весь этот блок перерисоваться мгновенно при смене темы
                  return BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, themeState) {
                      final bottomSystemInset = MediaQuery.viewPaddingOf(
                        context,
                      ).bottom;
                      _bottomSystemInset.updateFromMediaQuery(
                        bottomSystemInset,
                      );
                      final menuBottomMargin = _bottomSystemInset.inset + 16.0;

                      return CupertinoPageScaffold(
                        backgroundColor: AppColors.mainBackground,
                        child: Stack(
                          children: [
                            // Основной контент с поддержкой свайпов
                            _buildBody(state.user),
                            if (_currentIndex == 0) ...[
                              // Действие для текущего раздела чатов.
                              Positioned(
                                bottom: menuBottomMargin + 80,
                                right: 20,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.blurple,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blurple.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Semantics(
                                    label: _isDiscoveringServers
                                        ? _discoveryGridView
                                              ? 'Показать список серверов'
                                              : 'Показать сетку серверов'
                                        : 'Создать чат',
                                    button: true,
                                    child: GlassIconButton(
                                      key: ValueKey(
                                        _isDiscoveringServers
                                            ? 'discovery_layout_toggle'
                                            : 'create_chat_button',
                                      ),
                                      filled: true,
                                      icon: _isDiscoveringServers
                                          ? _discoveryGridView
                                                ? CupertinoIcons.list_bullet
                                                : CupertinoIcons.square_grid_2x2
                                          : CupertinoIcons.add,
                                      onTap: () {
                                        if (_isDiscoveringServers) {
                                          setState(
                                            () => _discoveryGridView =
                                                !_discoveryGridView,
                                          );
                                        } else {
                                          CreateChatScreen.open(context);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Стеклянное плавающее нижнее меню
                            Positioned(
                              bottom: menuBottomMargin,
                              left: 16,
                              right: 16,
                              child: BottomMenu(
                                user: state.user,
                                onTapTapped: _onTabTapped,
                                currentIndex: _currentIndex,
                                personalUnreadCount: personalUnredCount,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                if (state is ProfileFailure) {
                  return CupertinoPageScaffold(
                    backgroundColor: AppColors.mainBackground,
                    child: ErrorStateView(failure: state.error),
                  );
                }

                return CupertinoPageScaffold(
                  backgroundColor: AppColors.mainBackground,
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 12),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(UserModel user) {
    return PageView(
      key: ValueKey('home_pageview_${user.id}'),
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: [
        KeepAlivePage(
          key: ValueKey('chats_view_${user.id}'),
          child: ChatsView(
            personalUnreadCount: personalUnredCount,
            isReconnect: isReconnect,
            discoveryGridView: _discoveryGridView,
            onDiscoveryChanged: (value) {
              if (mounted && _isDiscoveringServers != value) {
                setState(() => _isDiscoveringServers = value);
              }
            },
          ),
        ),
        const KeepAlivePage(
          key: ValueKey('settings_view'),
          child: SettingsScreen(),
        ),
        KeepAlivePage(
          key: ValueKey('profile_view_${user.id}'),
          child: PersonalProfileScreen(),
        ),
      ],
    );
  }
}
