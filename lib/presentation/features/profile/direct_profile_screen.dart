// presentation/features/profile/direct_profile_screen.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_back_button.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_section.dart';
import 'package:disalive/presentation/utils/ui/color_service.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DirectProfileScreen extends StatefulWidget {
  final Chat chat;

  const DirectProfileScreen({super.key, required this.chat});

  @override
  State<StatefulWidget> createState() => DirectProfileScreenState();
}

class DirectProfileScreenState extends State<DirectProfileScreen> {
  late Chat _chat;

  @override
  void initState() {
    _chat = widget.chat;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded) {
          final updatedChat = state.chats.firstWhere(
            (c) => c.id == _chat.id,
            orElse: () => _chat,
          );

          if (updatedChat != _chat) {
            setState(() {
              _chat = updatedChat;
            });
          }
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.mainBackground,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _chat.user == null
                    ? Center(
                        child: Text(
                          'Не удалось загрузить профиль',
                          style: AppText.mediumTextStyle.copyWith(
                            color: AppColors.greyple,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          _buildContent(context, _chat.user!),
                          ProfileBackButton(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    final bannerColor = ColorService.parseColor(user.bannerColor);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bannerColor,
                      image: user.pathBanner != null
                          ? DecorationImage(
                              image: NetworkImage(user.pathBanner!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 70),
                        Text(
                          user.getDisplayName,
                          style: AppText.highTextStyle.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user.username}',
                          style: AppText.mediumTextStyle.copyWith(
                            color: AppColors.greyple,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (user.aboutMe != null &&
                            user.aboutMe!.isNotEmpty) ...[
                          ProfileSection(
                            title: 'ОБО МНЕ',
                            content: user.aboutMe!,
                          ),
                          const SizedBox(height: 20),
                        ],

                        ProfileSection(
                          title: 'В числе участников с',
                          content: user.getDateRegistration,
                        ),
                        const SizedBox(height: 24), // Отступ снизу для красоты
                      ],
                    ),
                  ),
                ],
              ),

              // 🎯 ИСХОДНОЕ ПОЗИЦИОНИРОВАНИЕ АВАТАРА
              Positioned(
                top: 80,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.mainBackground,
                    shape: BoxShape.circle,
                  ),
                  child: BuildAvatar(
                    wh: 80,
                    size: 42,
                    url: user.urlAvatar,
                    isBookmark: widget.chat.isSoloChat ?? false,
                    status: user.status,
                    statusSize: 18,
                  ),
                ),
              ),

              if (user.myThink != null && user.myThink!.isNotEmpty)
                Positioned(
                  top: 100,
                  left: 25 + 80 + 8,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mainBackground.withValues(
                              alpha: 0.95,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.blurple.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.quote_bubble,
                                color: AppColors.blurple,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  user.myThink!,
                                  style: AppText.lowTextStyle.copyWith(
                                    color: AppColors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
