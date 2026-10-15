import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/invites/invite_options.dart';
import 'package:disalive/presentation/features/invites/widgets/invite_chat_item.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_search_field.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/id_generator.dart';
import 'package:disalive/presentation/widgets/app_selection_sheet.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InviteServerScreen extends StatefulWidget {
  const InviteServerScreen({super.key, required this.server});

  final Server server;

  static Future<void> open(BuildContext context, {required Server server}) {
    final chatBloc = context.read<ChatBloc>();
    final messageBloc = context.read<MessageBloc>();
    final invitesBloc = context.read<InvitesBloc>();
    return SwipeToDismissRoute.push<void>(
      context,
      (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: chatBloc),
          BlocProvider.value(value: messageBloc),
          BlocProvider.value(value: invitesBloc),
        ],
        child: InviteServerScreen(server: server),
      ),
    );
  }

  @override
  State<InviteServerScreen> createState() => _InviteServerScreenState();
}

class _InviteServerScreenState extends State<InviteServerScreen> {
  InviteLifetime _lifetime = InviteLifetime.forever;
  InviteUsageLimit _usageLimit = InviteUsageLimit.unlimited;
  String _query = '';
  String? _code;
  InviteData? _createdInvite;
  Future<InviteData?>? _creation;
  bool _generating = false;
  bool _copying = false;
  final Set<int> _sending = {};
  final Set<int> _sent = {};
  int _codeGeneration = 0;

  InvitesBloc get _invitesBloc => context.read<InvitesBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _generateCode();
    });
  }

  Future<void> _generateCode() async {
    final generation = ++_codeGeneration;
    setState(() {
      _code = null;
      _createdInvite = null;
      _generating = true;
    });
    _invitesBloc.add(const GenerateInviteCode());
    final result = await _invitesBloc.stream.firstWhere(
      (state) =>
          state.lastCompleted == InviteOperation.generate ||
          state.failureFor(InviteOperation.generate) != null,
    );
    if (!mounted || generation != _codeGeneration) return;
    setState(() {
      _code = result.generatedCode;
      _generating = false;
    });
    if (result.failureFor(InviteOperation.generate) != null) {
      _showError('Не удалось создать ссылку-приглашение');
    }
  }

  Future<InviteData?> _ensureInvite() {
    if (_createdInvite != null) return Future.value(_createdInvite);
    if (_creation != null) return _creation!;
    final code = _code;
    if (code == null) return Future.value(null);
    final future = _createInvite(code);
    _creation = future;
    return future.whenComplete(() => _creation = null);
  }

  Future<InviteData?> _createInvite(String code) async {
    _invitesBloc.add(
      CreateInvite(
        entityId: widget.server.id!,
        entityType: EntityType.server,
        code: code,
        maxUsers: _usageLimit.value,
        expiresAt: _lifetime.durationSeconds,
      ),
    );
    final result = await _invitesBloc.stream.firstWhere(
      (state) =>
          state.lastCompleted == InviteOperation.create ||
          state.failureFor(InviteOperation.create) != null,
    );
    if (!mounted || code != _code) return null;
    if (result.failureFor(InviteOperation.create) != null) {
      _showError('Не удалось создать приглашение');
      return null;
    }
    final invite = result.createdInvite;
    if (invite?.code != code) {
      _showError('Не удалось получить приглашение');
      return null;
    }
    _createdInvite = invite;
    return invite;
  }

  void _showError(String message) {
    if (!mounted) return;
    CustomToast.open(context: context, message: message);
  }

  Future<void> _copyLink() async {
    if (_copying || _code == null) return;
    setState(() => _copying = true);
    try {
      final invite = await _ensureInvite();
      if (invite?.inviteUrl == null || !mounted) return;
      await Clipboard.setData(ClipboardData(text: invite!.inviteUrl!));
      if (!mounted) return;
      CustomToast.open(
        context: context,
        message: 'Ссылка скопирована',
        color: AppColors.actionGrey,
        icon: CupertinoIcons.check_mark_circled_solid,
      );
    } catch (_) {
      _showError('Не удалось скопировать ссылку');
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _sendToChat(Chat chat) async {
    if (_sending.contains(chat.id) ||
        _sent.contains(chat.id) ||
        _code == null) {
      return;
    }
    setState(() => _sending.add(chat.id));
    try {
      final invite = await _ensureInvite();
      if (invite?.inviteUrl == null || !mounted) return;
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
            text: invite!.inviteUrl,
            time: DateTime.now().toUtc().toString(),
            user: user,
          ),
        ),
      );
      setState(() => _sent.add(chat.id));
    } catch (_) {
      _showError('Не удалось отправить приглашение');
    } finally {
      if (mounted) setState(() => _sending.remove(chat.id));
    }
  }

  Future<void> _editOptions() async {
    var lifetime = _lifetime;
    var usageLimit = _usageLimit;
    final result =
        await showCupertinoModalPopup<
          ({InviteLifetime lifetime, InviteUsageLimit usage})
        >(
          context: context,
          builder: (sheetContext) => StatefulBuilder(
            builder: (context, updateSheet) => Container(
              height: 326,
              decoration: BoxDecoration(
                color: AppColors.mainBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Изменить ссылку приглашения',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Icon(
                              CupertinoIcons.xmark,
                              color: AppColors.iconGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _dropdownField(
                              label: 'Срок действия',
                              value: lifetime.label,
                              onTap: () async {
                                final selected = await _showDropdown(
                                  context,
                                  'Срок действия',
                                  InviteLifetime.values,
                                  (option) => option.label,
                                  lifetime,
                                  CupertinoIcons.clock,
                                );
                                if (selected != null) {
                                  updateSheet(() => lifetime = selected);
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            _dropdownField(
                              label: 'Максимальное количество использований',
                              value: usageLimit.label,
                              onTap: () async {
                                final selected = await _showDropdown(
                                  context,
                                  'Максимальное количество использований',
                                  InviteUsageLimit.values,
                                  (option) => option.label,
                                  usageLimit,
                                  CupertinoIcons.person_2,
                                );
                                if (selected != null) {
                                  updateSheet(() => usageLimit = selected);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          onPressed: () => Navigator.pop(sheetContext, (
                            lifetime: lifetime,
                            usage: usageLimit,
                          )),
                          child: const Text('Сохранить'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    if (!mounted || result == null) return;
    if (result.lifetime == _lifetime && result.usage == _usageLimit) return;
    setState(() {
      _lifetime = result.lifetime;
      _usageLimit = result.usage;
      _sent.clear();
    });
    await _generateCode();
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: AppColors.greyple, fontSize: 13)),
      const SizedBox(height: 8),
      CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.actionGrey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value, style: TextStyle(color: AppColors.white)),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                color: AppColors.greyple,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<T?> _showDropdown<T>(
    BuildContext context,
    String title,
    List<T> values,
    String Function(T) label,
    T selectedValue,
    IconData icon,
  ) => AppSelectionSheet.show<T>(
    context,
    title: title,
    selectedValue: selectedValue,
    options: [
      for (final value in values)
        AppSelectionOption(value: value, label: label(value), icon: icon),
    ],
  );

  Widget _buildFooter() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    decoration: BoxDecoration(
      color: AppColors.mainBackground,
      border: Border(
        top: BorderSide(color: AppColors.white.withValues(alpha: 0.12)),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Или отправьте другу ссылку-приглашение на сервер',
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
                  _generating
                      ? 'Создаём ссылку…'
                      : (_code == null
                            ? 'Не удалось создать ссылку'
                            : InviteData(code: _code).inviteUrl!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              key: const Key('copy_invite_link'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.actionGrey,
              onPressed: _code == null || _copying ? null : _copyLink,
              child: _copying
                  ? const CupertinoActivityIndicator()
                  : const Text('Скопировать'),
            ),
          ],
        ),
        if (_code == null && !_generating)
          CupertinoButton(
            onPressed: _generateCode,
            child: const Text('Повторить'),
          ),
        const SizedBox(height: 10),
        Text(
          _lifetime.validityText,
          style: TextStyle(color: AppColors.greyple, fontSize: 13),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          onPressed: _creation == null && !_generating ? _editOptions : null,
          child: const Text('Изменить ссылку приглашения'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => RoleScreenShell(
    title: 'Пригласить в ${widget.server.name ?? 'сервер'}',
    subtitle: 'Сервер',
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
                  ...chats.map(
                    (chat) => InviteChatItem(
                      chat: chat,
                      onSend: _code == null ? null : () => _sendToChat(chat),
                      isSending: _sending.contains(chat.id),
                      isSent: _sent.contains(chat.id),
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(),
          ],
        );
      },
    ),
  );
}
