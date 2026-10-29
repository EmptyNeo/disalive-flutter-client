import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/presentation/features/category_channel/bloc/category_channel_bloc.dart';
import 'package:disalive/presentation/features/channel_server/bloc/channel_server_bloc.dart';
import 'package:disalive/presentation/features/channel_server/channel_access_screen.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/chat_extra_panel.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:disalive/presentation/widgets/app_selection_sheet.dart';
import 'package:disalive/presentation/widgets/emoji_text_editing_controller.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChannelFormScreen extends StatefulWidget {
  const ChannelFormScreen({
    super.key,
    required this.serverId,
    required this.serverName,
    required this.channelsBloc,
    required this.categoriesBloc,
    this.channel,
    this.initialCategoryId,
  });

  final int serverId;
  final String serverName;
  final ChannelServerBloc channelsBloc;
  final CategoryChannelBloc categoriesBloc;
  final ChannelServer? channel;
  final int? initialCategoryId;

  static Future<void> open(
    BuildContext context, {
    required int serverId,
    required String serverName,
    required ChannelServerBloc channelsBloc,
    required CategoryChannelBloc categoriesBloc,
    ChannelServer? channel,
    int? initialCategoryId,
  }) async {
    await SwipeToDismissRoute.push<void>(
      context,
      (_) => ChannelFormScreen(
        serverId: serverId,
        serverName: serverName,
        channelsBloc: channelsBloc,
        categoriesBloc: categoriesBloc,
        channel: channel,
        initialCategoryId: initialCategoryId,
      ),
    );
  }

  @override
  State<ChannelFormScreen> createState() => _ChannelFormScreenState();
}

class _ChannelFormScreenState extends State<ChannelFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _maxParticipantsController;
  late String _type;
  late int? _categoryId;
  bool _isPrivate = false;
  bool _submitting = false;

  bool get _isEditing => widget.channel != null;

  @override
  void initState() {
    super.initState();
    _nameController = EmojiTextEditingController()
      ..text = widget.channel?.chatName ?? ''
      ..addListener(() => setState(() {}));
    _maxParticipantsController = TextEditingController(
      text: widget.channel?.maxParticipants?.toString() ?? '',
    )..addListener(() => setState(() {}));
    _type = widget.channel?.type ?? 'text';
    _categoryId = widget.channel?.categoryId ?? widget.initialCategoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _chooseCategory(List<CategoryChannel> categories) async {
    final selected = await AppSelectionSheet.show<int>(
      context,
      title: 'Категория канала',
      selectedValue: _categoryId ?? 0,
      options: [
        const AppSelectionOption(
          value: 0,
          label: 'Нет категории',
          icon: CupertinoIcons.clear,
        ),
        for (final category in categories)
          if (category.id != null)
            AppSelectionOption(
              value: category.id!,
              label: category.name ?? 'Категория',
              icon: CupertinoIcons.folder,
            ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() => _categoryId = selected == 0 ? null : selected);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final limitText = _maxParticipantsController.text.trim();
    final maxParticipants = limitText.isEmpty ? null : int.tryParse(limitText);
    if (name.isEmpty ||
        _submitting ||
        (_type == 'voice' &&
            limitText.isNotEmpty &&
            (maxParticipants == null ||
                maxParticipants < 1 ||
                maxParticipants > 2147483647))) {
      return;
    }

    if (!_isEditing && _isPrivate) {
      final created = await ChannelAccessScreen.open(
        context,
        serverId: widget.serverId,
        serverName: widget.serverName,
        name: name,
        type: _type,
        categoryId: _categoryId,
        maxParticipants: _type == 'voice' ? maxParticipants : null,
        channelsBloc: widget.channelsBloc,
      );
      if (created && mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _submitting = true);
    final repository = sl<ChannelServerRepository>();
    final result = _isEditing
        ? await repository.update(
            widget.channel!.id!,
            name: name,
            categoryId: _categoryId ?? 0,
            maxParticipants: _type == 'voice' ? maxParticipants : null,
          )
        : await repository.create(
            widget.serverId,
            name,
            type: _type,
            categoryId: _categoryId,
            maxParticipants: _type == 'voice' ? maxParticipants : null,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (channel) {
        widget.channelsBloc.add(
          ServerChannelUpserted(widget.serverId, channel.toMap()),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    final limitText = _maxParticipantsController.text.trim();
    final parsedLimit = int.tryParse(limitText);
    final validLimit =
        _type != 'voice' ||
        limitText.isEmpty ||
        (parsedLimit != null && parsedLimit > 0 && parsedLimit <= 2147483647);
    return RoleScreenShell(
      title: _isEditing ? 'Редактировать канал' : 'Создать канал',
      subtitle: widget.serverName,
      actionTitle: _isEditing
          ? 'Сохранить'
          : (_isPrivate ? 'Далее' : 'Создать'),
      onAction: _submit,
      actionEnabled: name.isNotEmpty && validLimit && !_submitting,
      actionLoading: _submitting,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _sectionTitle('Тип канала'),
          const SizedBox(height: 8),
          _typeOption('text', CupertinoIcons.number, 'Текстовый канал'),
          const SizedBox(height: 8),
          _typeOption('voice', CupertinoIcons.speaker_2, 'Голосовой канал'),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Тип канала нельзя изменить',
                style: TextStyle(color: AppColors.greyple, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          _sectionTitle('Название канала'),
          const SizedBox(height: 8),
          CupertinoTextField(
            key: const ValueKey('channel_name_field'),
            controller: _nameController,
            inputFormatters: const [EmojiAtomicDeletionFormatter()],
            maxLength: 30,
            placeholder: 'Название канала',
            padding: const EdgeInsets.all(14),
            style: TextStyle(color: AppColors.white),
            decoration: BoxDecoration(
              color: AppColors.actionGrey,
              borderRadius: BorderRadius.circular(13),
            ),
            suffix: CupertinoButton(
              key: const ValueKey('channel_name_emoji_button'),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              onPressed: () => ChatExtraPanel.showEmojiPicker(
                context,
                controller: _nameController,
              ),
              child: Icon(CupertinoIcons.smiley, color: AppColors.greyple),
            ),
          ),
          if (_type == 'voice') ...[
            const SizedBox(height: 24),
            _sectionTitle('Максимальное количество участников'),
            const SizedBox(height: 8),
            CupertinoTextField(
              key: const ValueKey('channel_max_participants_field'),
              controller: _maxParticipantsController,
              keyboardType: TextInputType.number,
              placeholder: 'Без ограничения',
              padding: const EdgeInsets.all(14),
              style: TextStyle(color: AppColors.white),
              decoration: BoxDecoration(
                color: AppColors.actionGrey,
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            if (!validLimit)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Введите целое число больше нуля',
                  style: TextStyle(color: AppColors.errorRed, fontSize: 12),
                ),
              ),
          ],
          const SizedBox(height: 24),
          _sectionTitle('Категория'),
          const SizedBox(height: 8),
          BlocBuilder<CategoryChannelBloc, CategoryChannelState>(
            bloc: widget.categoriesBloc,
            builder: (context, state) {
              final categories =
                  state is ChannelCategoriesLoaded &&
                      state.serverId == widget.serverId
                  ? state.categories
                  : const <CategoryChannel>[];
              final category = categories.where(
                (item) => item.id == _categoryId,
              );
              final label = category.isEmpty
                  ? 'Нет категории'
                  : (category.first.name ?? 'Категория');
              return CupertinoButton(
                key: const ValueKey('channel_category_picker'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                color: AppColors.actionGrey,
                borderRadius: BorderRadius.circular(13),
                onPressed: () => _chooseCategory(categories),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: EmojiTextParser.parse(
                            label,
                            emojiSize: 17,
                            animateEmoji: false,
                          ),
                        ),
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_down,
                      color: AppColors.greyple,
                      size: 16,
                    ),
                  ],
                ),
              );
            },
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Приватный канал',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                  CupertinoSwitch(
                    key: const ValueKey('private_channel_switch'),
                    value: _isPrivate,
                    activeTrackColor: AppColors.blurple,
                    onChanged: (value) => setState(() => _isPrivate = value),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: TextStyle(color: AppColors.greyple, fontSize: 13));

  Widget _typeOption(String type, IconData icon, String label) {
    final selected = _type == type;
    return CupertinoButton(
      key: ValueKey('channel_type_$type'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      color: AppColors.lightGrey,
      borderRadius: BorderRadius.circular(13),
      onPressed: _isEditing ? null : () => setState(() => _type = type),
      child: Row(
        children: [
          Icon(icon, color: selected ? AppColors.blurple : AppColors.greyple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: AppColors.white)),
          ),
          Icon(
            selected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color: selected ? AppColors.blurple : AppColors.greyple,
          ),
        ],
      ),
    );
  }
}
