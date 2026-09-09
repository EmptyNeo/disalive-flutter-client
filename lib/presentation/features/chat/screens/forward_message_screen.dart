import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/id_generator.dart';
import 'package:disalive/presentation/widgets/actions/action_button.dart';
import 'package:disalive/presentation/widgets/actions/action_chats_sliver.dart';
import 'package:disalive/presentation/widgets/actions/action_header.dart';
import 'package:disalive/presentation/widgets/actions/action_search_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForwardMessageScreen extends StatefulWidget {
  final Message message;

  const ForwardMessageScreen({super.key, required this.message});

  static Future<void> open(
    BuildContext context,
    ChatBloc chatBloc,
    MessageBloc messageBloc,
    Message message,
  ) {
    return SwipeToDismissRoute.push(
      context,
      (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: chatBloc),
          BlocProvider.value(value: messageBloc),
        ],
        child: ForwardMessageScreen(message: message),
      ),
    );
  }

  @override
  State<ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<ForwardMessageScreen> {
  late final ChatBloc _chatBloc;
  late final MessageBloc _messageBloc;
  final TextEditingController _searchController = TextEditingController();
  final Map<int, Chat> _selected = {};

  int? get _currentUserId => sl<UserRepository>().getCurrentUser()?.id;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _messageBloc = context.read<MessageBloc>();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    // Обязательно сбрасываем поиск в bloc при закрытии экрана — иначе
    // список чатов на предыдущем экране останется отфильтрованным по
    // последнему запросу, который вводили здесь.
    _chatBloc.add(SearchChats(''));
    super.dispose();
  }

  void _onSearchChanged() {
    _chatBloc.add(SearchChats(_searchController.text.trim()));
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

  Future<void> _onForwardPressed() async {
    if (_selected.isEmpty) return;

    for (Chat chat in _selected.values.toList()) {
      var localGeneratedId = '';

      if (widget.message.localGeneratedId != null) {
        localGeneratedId = widget.message.localGeneratedId ?? '';
      } else {
        localGeneratedId = IdGenerator.generateId();
      }

      // Создаем локальное сообщение
      final localMessage = Message(
        localGeneratedId: localGeneratedId,
        chatId: chat.id,
        userId: _currentUserId,
        time: DateTime.now().toUtc().toString(),
        forwardMessage: widget.message,
        forwardMessageId: widget.message.id,
      );

      _messageBloc.add(
        CreateMessage(
          chatId: chat.id,
          entityId: chat.id,
          entityType: EntityType.chat,
          localGeneratedId: localGeneratedId,
          message: localMessage,
        ),
      );
    }

    if (mounted) Navigator.of(context).maybePop();
  }

  List<Chat> _chatsFrom(ChatState state) {
    if (state is! ChatLoaded) return const [];
    return state.chats.toList();
  }

  @override
  Widget build(BuildContext context) {
    bool canPress = _selected.isNotEmpty;
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
                  // Хэдер, поле поиска и список друзей — один общий скролл,
                  // а не хэдер+поиск фиксированные сверху и список отдельно.
                  Positioned.fill(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: BlocBuilder<ChatBloc, ChatState>(
                            bloc: _chatBloc,
                            builder: (context, state) {
                              if (state is ChatLoaded) {
                                final visibleCount = state.chats.length;
                                final remaining =
                                    (visibleCount - _selected.length).clamp(
                                      0,
                                      visibleCount,
                                    );

                                return ActionHeader(
                                  title: "Переслать сообщение",
                                  subtitle:
                                      "Вы можете выбрать ещё $remaining чатов",
                                );
                              }

                              return ActionHeader(
                                title: "Загрузка...",
                                subtitle: null,
                              );
                            },
                          ),
                        ),
                        SliverToBoxAdapter(child: ActionSearchField()),
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        ActionChatsSliver(
                          onTap: _toggleSelected,
                          filter: _chatsFrom,
                          selected: _selected,
                        ),
                        // Запас снизу, чтобы список не прятался под
                        // нависающей кнопкой (у неё нет своего фона/бара).
                        const SliverToBoxAdapter(child: SizedBox(height: 88)),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ActionButton(
                      onTap: _onForwardPressed,
                      canPress: canPress,
                      title: "Отправить сообщение",
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
}
