import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/members/widgets/members_list.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_back_button.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupProfileScreen extends StatefulWidget {
  final Chat chat;

  const GroupProfileScreen({super.key, required this.chat});

  static Future<void> open(BuildContext context, Chat chat) {
    return Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => GroupProfileScreen(chat: chat)),
    );
  }

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  late final MembersBloc _membersBloc;

  @override
  void initState() {
    super.initState();
    _membersBloc = context.read<MembersBloc>();

    _membersBloc.add(
      GetMembers(entityId: widget.chat.id, entityType: EntityType.chat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
              child: Stack(
                children: [_buildUnifiedList(), const ProfileBackButton()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedList() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 24),
            child: Column(
              children: [
                BuildAvatar(
                  url: widget.chat.urlAvatar,
                  wh: 80,
                  size: 45,
                  isBookmark: false,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.chat.name,
                    style: AppText.highTextStyle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        MembersList(chat: widget.chat),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
