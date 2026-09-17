import 'package:dartz/dartz_unsafe.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/actions/action_button.dart';
import 'package:disalive/presentation/widgets/actions/action_chats_sliver.dart';
import 'package:disalive/presentation/widgets/actions/action_header.dart';
import 'package:disalive/presentation/widgets/actions/action_search_field.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddMembersScreen extends StatefulWidget {
  final Chat chat;

  const AddMembersScreen({super.key, required this.chat});

  static Future<void> open(BuildContext context, Chat chat) {
    final chatBloc = context.read<ChatBloc>();
    return SwipeToDismissRoute.push(
      context,
      (context) => BlocProvider.value(
        value: chatBloc,
        child: AddMembersScreen(chat: chat),
      ),
    );
  }

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  late final ChatBloc _chatBloc;
  final Map<int, Chat> _selected = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
  }

  void _toggleSelected(Chat chat) {
    final id = chat.id;
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
      } else {
        _selected[id] = chat;
      }
    });
  }

  List<int> getUserIds() {
    return _selected.values
        .where((chat) => chat.user != null)
        .map((chat) => chat.user!.getId)
        .toList();
  }

  Future<void> _onAddPressed() async {
    final userIds = getUserIds();
    if (userIds.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await sl<MembersRepository>().add(widget.chat.id, userIds);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        CustomToast.show(context: context, message: failure.message);
      },
      (response) {
        Navigator.of(context).maybePop();
      },
    );
  }

  List<Chat> _chatsFrom(ChatState state) {
    if (state is! ChatLoaded) return [];

    final user = sl<UserRepository>().getCurrentUser();
    final currentMembers = widget.chat.members;

    if (user == null || currentMembers == null) return [];

    final currentMemberIds = currentMembers.map((m) => m.fkUser).toSet();

    return state.chats.where((chat) {
      if (!chat.isPersonalChat) return false;

      final otherMember = chat.members?.firstWhere(
        (m) => m.fkUser != user.id,
        orElse: () => Member(fkUser: -1),
      );

      final otherUserId = otherMember?.fkUser ?? -1;

      return otherUserId != -1 && !currentMemberIds.contains(otherUserId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _selected.isNotEmpty && !_isLoading;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                children: [
                  Positioned.fill(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        const SliverToBoxAdapter(child: ActionSearchField()),
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        ActionChatsSliver(
                          onTap: _toggleSelected,
                          filter: _chatsFrom,
                          selected: _selected,
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 88)),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ActionButton(
                      onTap: _onAddPressed,
                      canPress: canAdd,
                      isLoading: _isLoading,
                      title: 'Добавить участников',
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

  Widget _buildHeader() {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: _chatBloc,
      builder: (context, state) {
        final visibleChats = _chatsFrom(state);
        final visibleCount = visibleChats.length;

        final selectedInVisibleCount = visibleChats
            .where((chat) => _selected.containsKey(chat.id))
            .length;

        final remaining = visibleCount - selectedInVisibleCount;

        return ActionHeader(
          title: 'Выберите друзей',
          subtitle: 'Вы можете добавить ещё $remaining друзей',
        );
      },
    );
  }
}
