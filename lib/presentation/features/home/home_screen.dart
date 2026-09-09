import 'dart:ui';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/repositories/chat_repository_impl.dart';
import 'package:disalive/domain/enums/user_response_type.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat_server/bloc/chat_server_bloc.dart';
import 'package:disalive/presentation/features/home/screens/create_chat_screen.dart';
import 'package:disalive/presentation/features/home/widgets/chats_view.dart';
import 'package:disalive/presentation/features/components/bottom_menu.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
import 'package:disalive/presentation/features/home/widgets/supportive/keep_alive_page.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  int personalUnredCount = 0;
  bool isReconnect = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
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
        BlocProvider<ChatServerBloc>(
          lazy: false,
          create: (_) => sl<ChatServerBloc>()..add(ConnectToChatServer()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) =>
              sl<ProfileBloc>()
                ..add(GetProfile(userResponseType: UserResponseType.user)),
        ),
        BlocProvider<ChatBloc>(create: (_) => sl<ChatBloc>()..add(GetChats())),
        BlocProvider<RequestsBloc>(
          create: (_) => sl<RequestsBloc>()..add(GetRequests(true)),
        ),
        BlocProvider<MessageBloc>(create: (_) => sl<MessageBloc>()),
      ],
      child: MultiBlocListener(
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
                context.read<ChatBloc>().setupListeners();
                context.read<MessageBloc>().setupListeners();
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
        ],
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return CupertinoPageScaffold(
                backgroundColor: AppColors.mainBackground,
                child: const Center(child: CupertinoActivityIndicator()),
              );
            }

            if (state is ProfileLoaded) {
              final bottomSafeArea = MediaQuery.of(context).padding.bottom;
              final menuBottomMargin = bottomSafeArea > 0
                  ? bottomSafeArea
                  : 16.0;

              return CupertinoPageScaffold(
                backgroundColor: AppColors.mainBackground,
                child: Stack(
                  children: [
                    // Основной контент с поддержкой свайпов
                    _buildBody(state.user),

                    // Кнопка создания чата (FAB)
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
                              color: AppColors.blurple.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: GlassIconButton(
                          filled: true,
                          icon: CupertinoIcons.add,
                          onTap: () {
                            CreateChatScreen.open(context);
                          },
                        ),
                      ),
                    ),

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
            }

            if (state is ProfileFailure) {
              return CupertinoPageScaffold(
                backgroundColor: AppColors.mainBackground,
                child: Center(
                  child: Text(
                    'Ошибка: ${state.error}',
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                ),
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
      ),
    );
  }

  Widget _buildBody(UserModel user) {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: [
        KeepAlivePage(
          child: ChatsView(
            personalUnreadCount: personalUnredCount,
            isReconnect: isReconnect,
          ),
        ),
        // Здесь рендерятся чаты
        const KeepAlivePage(
          child: Center(
            child: Text(
              'Настройки',
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
        KeepAlivePage(
          child: Center(
            child: Text(
              'Профиль: ${user.displayName}',
              style: const TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
