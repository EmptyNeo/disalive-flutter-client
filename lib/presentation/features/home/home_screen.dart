import 'dart:async';
import 'dart:io';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/repositories/local_chat_state_repository.dart';
import 'package:disalive/domain/enums/user_response_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/enums/appeal_target_type.dart';
import 'package:disalive/presentation/features/appeals/blocked_entity_notice.dart';
import 'package:disalive/presentation/features/appeals/bloc/appeal_bloc.dart';
import 'package:disalive/domain/repositories/appeal_repository.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/gifs_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/media_stats_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/preferred_reactions_repository.dart';
import 'package:disalive/domain/repositories/preferred_emojis_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/repositories/requests_repository.dart';
import 'package:disalive/domain/repositories/session_repository.dart';
import 'package:disalive/domain/repositories/server_emoji_pack_repository.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';
import 'package:disalive/domain/repositories/stickers_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/repositories/user_stickers_pack_repository.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
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
import 'package:disalive/presentation/features/updates/rustore_update_sheet.dart';
import 'package:disalive/presentation/features/home/widgets/chats_view.dart';
import 'package:disalive/presentation/features/components/bottom_menu.dart';
import 'package:disalive/presentation/features/login.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/profile/personal_profile_screen.dart';
import 'package:disalive/presentation/features/reactions/bloc/preferred_reactions_bloc.dart';
import 'package:disalive/presentation/features/emojis/bloc/preferred_emojis_bloc.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/settings/settings_screen.dart';
import 'package:disalive/presentation/features/home/widgets/supportive/keep_alive_page.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_rustore_update/flutter_rustore_update.dart';

// 🎯 1. ДОБАВЛЯЕМ ИМПОРТЫ ТЕМЫ
import 'package:disalive/presentation/bloc/theme/theme_cubit.dart';
import 'package:disalive/presentation/bloc/theme/theme_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static BuildContext? scopeContext;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  int personalUnredCount = 0;
  bool isReconnect = false;
  bool _isDiscoveringServers = false;
  bool _discoveryGridView = false;
  bool _incomingCallDialogOpen = false;
  bool _checkedForUpdates = false;
  bool _checkingBanStatus = false;
  String? _banStatusError;

  Future<void> _checkBanStatus(BuildContext context) async {
    if (_checkingBanStatus) return;
    setState(() {
      _checkingBanStatus = true;
      _banStatusError = null;
    });
    final result = await sl<AppealRepository>().getTargets();
    if (!mounted || !context.mounted) return;
    result.fold(
      (failure) => setState(() {
        _checkingBanStatus = false;
        _banStatusError = failure.message;
      }),
      (targets) {
        final stillBanned = targets.any(
          (target) => target.type == AppealTargetType.user,
        );
        setState(() {
          _checkingBanStatus = false;
          _banStatusError = stillBanned
              ? 'Учётная запись всё ещё заблокирована.'
              : null;
        });
        if (!stillBanned) {
          sl<UserRepository>().clearCurrentUser();
          context.read<ProfileBloc>().add(
            GetProfile(userResponseType: UserResponseType.user),
          );
        }
      },
    );
  }

  Future<void> _confirmBlockedLogout(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Выйти из аккаунта?',
      description: 'Для входа потребуется снова ввести данные учётной записи.',
      confirmText: 'Выйти',
    );
    if (confirmed == true && context.mounted) {
      context.read<SessionBloc>().add(LogoutLocally());
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checkedForUpdates || !Platform.isAndroid) return;
    _checkedForUpdates = true;
    try {
      final package = await PackageInfo.fromPlatform();
      if (package.installerStore == 'ru.vk.store') {
        try {
          final info = await RustoreUpdateClient.info();
          if (!mounted) return;
          if (info.updateAvailabilityValue == UpdateAvailability.available ||
              info.installStatusValue == InstallStatus.downloaded) {
            unawaited(
              showRuStoreUpdateSheet(
                context,
                downloaded: info.installStatusValue == InstallStatus.downloaded,
              ),
            );
          }
        } catch (_) {
          // RuStore also manages updates independently of this prompt.
        }
      }
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
    unawaited(_loadServerEmojis());
  }

  Future<void> _loadServerEmojis() async {
    final emojiHandler = EmojisHandler.instance;
    await emojiHandler.initialize();
    await emojiHandler.loadServerEmojiPacks(sl<ServerEmojiPackRepository>());
    if (mounted) setState(() {});
  }

  void _onCallScreenExited() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
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
          create: (_) {
            final bloc = ProfileBloc(
              sl<UserRepository>(),
              sl<AuthBloc>(),
              sl<WsEventBus>(),
            );
            final auth = context.read<AuthBloc>().state;
            if (auth is! AuthAuthenticated || !auth.accountBanned) {
              bloc.add(GetProfile(userResponseType: UserResponseType.user));
            }
            return bloc;
          },
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
        BlocProvider<PreferredEmojisBloc>(
          lazy: false,
          create: (_) =>
              PreferredEmojisBloc(sl<PreferredEmojisRepository>())
                ..add(const LoadPreferredEmojis()),
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
                final auth = context.watch<AuthBloc>().state;
                final accountBanned = state is ProfileLoaded
                    ? state.user.isBannedUser
                    : (auth is AuthAuthenticated && auth.accountBanned) ||
                          (state is ProfileFailure &&
                              state.error is AccountBannedFailure);
                if (accountBanned) {
                  return PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, _) {
                      if (!didPop) unawaited(_confirmBlockedLogout(context));
                    },
                    child: CupertinoPageScaffold(
                      backgroundColor: AppColors.mainBackground,
                      child: SafeArea(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BlocProvider(
                                  create: (_) =>
                                      sl<AppealBloc>()..add(LoadAppeals()),
                                  child: const BlockedEntityNotice(
                                    type: AppealTargetType.user,
                                    id: null,
                                    name: 'Учётная запись',
                                    message:
                                        'Ваша учётная запись заблокирована. Вы можете подать апелляцию.',
                                  ),
                                ),
                                CupertinoButton(
                                  onPressed: _checkingBanStatus
                                      ? null
                                      : () => _checkBanStatus(context),
                                  child: _checkingBanStatus
                                      ? const CupertinoActivityIndicator()
                                      : const Text('Проверить статус'),
                                ),
                                if (_banStatusError != null)
                                  Text(
                                    _banStatusError!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.errorRed),
                                  ),
                                CupertinoButton(
                                  onPressed: () =>
                                      _confirmBlockedLogout(context),
                                  child: Text(
                                    'Выйти из аккаунта',
                                    style: TextStyle(color: AppColors.greyple),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
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
                      return CupertinoPageScaffold(
                        backgroundColor: AppColors.mainBackground,
                        child: Stack(
                          children: [
                            // Основной контент с поддержкой свайпов
                            _buildBody(state.user),
                            if (_currentIndex == 0) ...[
                              // Действие для текущего раздела чатов.
                              Positioned(
                                bottom: 0,
                                right: 20,
                                child: SafeArea(
                                  top: false,
                                  left: false,
                                  right: false,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 96),
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
                                                    : CupertinoIcons
                                                          .square_grid_2x2
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
                                ),
                              ),
                            ],

                            // Стеклянное плавающее нижнее меню
                            Positioned(
                              bottom: 0,
                              left: 16,
                              right: 16,
                              child: SafeArea(
                                top: false,
                                left: false,
                                right: false,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: BottomMenu(
                                    user: state.user,
                                    onTapTapped: _onTabTapped,
                                    currentIndex: _currentIndex,
                                    personalUnreadCount: personalUnredCount,
                                  ),
                                ),
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
