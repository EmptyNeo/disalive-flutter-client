// presentation/features/profile/direct_profile_screen.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/profile/widgets/direct_profile_content.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_back_button.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
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
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _chat.user == null
                    ? Center(
                        child: Text(
                          'Не удалось загрузить профиль',
                          style: TextStyle(
                            color: AppColors.greyple,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 🎯 Используем вынесенный виджет
                          DirectProfileContent(
                            user: _chat.user!,
                            isSoloChat: widget.chat.isSoloChat ?? false,
                          ),
                          const ProfileBackButton(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
