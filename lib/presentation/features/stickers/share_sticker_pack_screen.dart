import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/invites/widgets/invite_chat_item.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_search_field.dart';
import 'package:disalive/presentation/features/stickers/sticker_pack_link.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/id_generator.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareStickerPackScreen extends StatefulWidget {
  const ShareStickerPackScreen({super.key, required this.pack});

  final StickerPack pack;

  static Future<void> open(BuildContext context, {required StickerPack pack}) {
    final chatBloc = context.read<ChatBloc>();
    final messageBloc = context.read<MessageBloc>();
    return SwipeToDismissRoute.push<void>(
      context,
      (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: chatBloc),
          BlocProvider.value(value: messageBloc),
        ],
        child: ShareStickerPackScreen(pack: pack),
      ),
    );
  }

  @override
  State<ShareStickerPackScreen> createState() => _ShareStickerPackScreenState();
}

class _ShareStickerPackScreenState extends State<ShareStickerPackScreen> {
  String _query = '';
  final Set<int> _sending = {};
  final Set<int> _sent = {};

  String get _url => stickerPackUrl(widget.pack.id);

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _url));
    if (!mounted) return;
    CustomToast.open(
      context: context,
      message: 'Ссылка скопирована',
      color: AppColors.actionGrey,
      icon: CupertinoIcons.check_mark_circled_solid,
    );
  }

  Future<void> _sendToChat(Chat chat) async {
    if (_sending.contains(chat.id) || _sent.contains(chat.id)) return;
    setState(() => _sending.add(chat.id));
    try {
      final user = sl<UserRepository>().getCurrentUser();
      final localId = IdGenerator.generateId();
      context.read<MessageBloc>().add(
        CreateMessage(
          chatId: chat.id,
          entityId: chat.id,
          entityType: EntityType.chat,
          localGeneratedId: localId,
          message: Message(
            localGeneratedId: localId,
            chatId: chat.id,
            userId: user?.id,
            text: _url,
            time: DateTime.now().toUtc().toString(),
            user: user,
          ),
        ),
      );
      if (mounted) setState(() => _sent.add(chat.id));
    } catch (_) {
      if (mounted) {
        CustomToast.open(
          context: context,
          message: 'Не удалось отправить набор стикеров',
        );
      }
    } finally {
      if (mounted) setState(() => _sending.remove(chat.id));
    }
  }

  Widget _footer() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.mainBackground,
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Или отправьте другу ссылку на набор стикеров',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.actionGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              key: const ValueKey('copy_sticker_pack_link'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.actionGrey,
              onPressed: _copyLink,
              child: const Text('Скопировать'),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => RoleScreenShell(
    title: 'Поделиться набором',
    subtitle: widget.pack.name,
    child: BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final chats = state is ChatLoaded
            ? state.chats
                  .where(
                    (chat) =>
                        chat.isPersonalChat &&
                        chat.name.toLowerCase().contains(_query),
                  )
                  .toList()
            : <Chat>[];
        return Column(
          children: [
            const SizedBox(height: 12),
            RoleSearchField(
              placeholder: 'Поиск личных чатов',
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.white.withValues(alpha: 0.12),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (state is ChatLoading || state is ChatInitial)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else if (state is ChatFailure)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Не удалось загрузить личные чаты',
                        style: TextStyle(color: AppColors.greyple),
                      ),
                    )
                  else if (chats.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _query.isEmpty
                            ? 'Личных чатов пока нет'
                            : 'Ничего не найдено',
                        style: TextStyle(color: AppColors.greyple),
                      ),
                    ),
                  for (final chat in chats)
                    InviteChatItem(
                      chat: chat,
                      onSend: () => _sendToChat(chat),
                      isSending: _sending.contains(chat.id),
                      isSent: _sent.contains(chat.id),
                    ),
                ],
              ),
            ),
            _footer(),
          ],
        );
      },
    ),
  );
}
