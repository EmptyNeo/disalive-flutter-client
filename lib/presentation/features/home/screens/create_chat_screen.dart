import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/actions/action_button.dart';
import 'package:disalive/presentation/widgets/actions/action_chats_sliver.dart';
import 'package:disalive/presentation/widgets/actions/action_header.dart';
import 'package:disalive/presentation/widgets/actions/action_search_field.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  static Future<void> open(BuildContext context) {
    final chatBloc = context.read<ChatBloc>();
    return SwipeToDismissRoute.push(
      context,
      (context) =>
          BlocProvider.value(value: chatBloc, child: const CreateChatScreen()),
    );
  }

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  late final ChatBloc _chatBloc;
  final Map<int, Chat> _selected = {};

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

  Future<void> _onCreatePressed() async {
    if (_selected.length < 2) return;
    final result = await sl<ChatRepository>().create(_selected.values.toList());
    result.fold((failure) {
      CustomToast.show(context, failure.message);
    }, (response) {});
    if (mounted) Navigator.of(context).maybePop();
  }

  List<Chat> _chatsFrom(ChatState state) {
    if (state is! ChatLoaded) return const [];
    return state.chats.where((c) => c.isPersonalChat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _selected.length >= 2;

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
                      onTap: _onCreatePressed,
                      canPress: canCreate,
                      title: 'Создать групповой чат',
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
        final visibleCount = _chatsFrom(state).length;
        final remaining = (visibleCount - _selected.length).clamp(
          0,
          visibleCount,
        );

        return ActionHeader(
          title: 'Выберите друзей',
          subtitle: 'Вы можете добавить ещё $remaining друзей',
        );
      },
    );
  }
}
