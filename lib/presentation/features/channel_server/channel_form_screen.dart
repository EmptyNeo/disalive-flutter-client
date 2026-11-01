import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/presentation/features/category_channel/bloc/category_channel_bloc.dart';
import 'package:disalive/presentation/features/channel_server/bloc/channel_server_bloc.dart';
import 'package:disalive/presentation/features/channel_server/channel_access_screen.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/chat_extra_panel.dart';
import 'package:disalive/presentation/features/emojis/bloc/preferred_emojis_bloc.dart';
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
    final preferredEmojisBloc = context.read<PreferredEmojisBloc>();
    await SwipeToDismissRoute.push<void>(
      context,
      (_) => BlocProvider.value(
        value: preferredEmojisBloc,
        child: ChannelFormScreen(
          serverId: serverId,
          serverName: serverName,
          channelsBloc: channelsBloc,
          categoriesBloc: categoriesBloc,
          channel: channel,
          initialCategoryId: initialCategoryId,
        ),
      ),
    );
  }

  @override
  State<ChannelFormScreen> createState() => _ChannelFormScreenState();
}

class _ChannelFormScreenState extends State<ChannelFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _maxParticipantsController;
  late int _slowModeSeconds;
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
    _slowModeSeconds = widget.channel?.slowModeSeconds ?? 0;
    _type = widget.channel?.type ?? 'text';
    _categoryId = widget.channel?.categoryId ?? widget.initialCategoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  static const _slowModePresets = <(int, String)>[
    (0, 'Выключен'),
    (5, '5 секунд'),
    (10, '10 секунд'),
    (15, '15 секунд'),
    (30, '30 секунд'),
    (60, '1 минута'),
    (120, '2 минуты'),
    (300, '5 минут'),
    (600, '10 минут'),
    (900, '15 минут'),
    (1800, '30 минут'),
    (3600, '1 час'),
    (7200, '2 часа'),
    (21600, '6 часов'),
  ];

  String _slowModeLabel(int seconds) {
    for (final (value, label) in _slowModePresets) {
      if (value == seconds) return label;
    }
    if (seconds >= 3600 && seconds % 3600 == 0) {
      return '${seconds ~/ 3600} ч.';
    }
    if (seconds >= 60 && seconds % 60 == 0) {
      return '${seconds ~/ 60} мин.';
    }
    if (seconds >= 60) {
      return '${seconds ~/ 60} мин. ${seconds % 60} сек.';
    }
    return '$seconds сек.';
  }

  Future<void> _chooseSlowMode() async {
    final options = [
      if (!_slowModePresets.any((preset) => preset.$1 == _slowModeSeconds))
        AppSelectionOption<int>(
          value: _slowModeSeconds,
          label: 'Текущее значение · ${_slowModeLabel(_slowModeSeconds)}',
        ),
      const AppSelectionOption<int>(
        value: -1,
        label: 'Своё значение',
        icon: CupertinoIcons.slider_horizontal_3,
      ),
      for (final (seconds, label) in _slowModePresets)
        AppSelectionOption<int>(
          value: seconds,
          label: label,
          icon: seconds == 0 ? CupertinoIcons.clear : CupertinoIcons.timer,
        ),
    ];
    final selected = await AppSelectionSheet.show<int>(
      context,
      title: 'Медленный режим',
      selectedValue: _slowModeSeconds,
      options: options,
    );
    if (selected == -1) {
      final customValue = await showCupertinoDialog<int>(
        context: context,
        builder: (_) => const _CustomSlowModeDialog(),
      );
      if (customValue == null || !mounted) return;
      setState(() => _slowModeSeconds = customValue);
      return;
    }
    if (selected == null || !mounted) return;
    setState(() => _slowModeSeconds = selected);
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
    final slowModeSeconds = _slowModeSeconds;
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
        slowModeSeconds: _type == 'text' ? slowModeSeconds : 0,
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
            slowModeSeconds: _type == 'text' ? slowModeSeconds : 0,
          )
        : await repository.create(
            widget.serverId,
            name,
            type: _type,
            categoryId: _categoryId,
            maxParticipants: _type == 'voice' ? maxParticipants : null,
            slowModeSeconds: _type == 'text' ? slowModeSeconds : 0,
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
          if (_type == 'text') ...[
            const SizedBox(height: 24),
            _sectionTitle('Медленный режим'),
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('channel_slow_mode_picker'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              color: AppColors.actionGrey,
              borderRadius: BorderRadius.circular(13),
              onPressed: _chooseSlowMode,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _slowModeLabel(_slowModeSeconds),
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: AppColors.greyple,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Выберите, как часто участники могут отправлять сообщения.',
                style: TextStyle(color: AppColors.greyple, fontSize: 12),
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

enum _SlowModeUnit { seconds, minutes, hours }

class _CustomSlowModeDialog extends StatefulWidget {
  const _CustomSlowModeDialog();

  @override
  State<_CustomSlowModeDialog> createState() => _CustomSlowModeDialogState();
}

class _CustomSlowModeDialogState extends State<_CustomSlowModeDialog> {
  late final TextEditingController _controller;
  _SlowModeUnit _unit = _SlowModeUnit.minutes;

  int get _unitMultiplier => switch (_unit) {
    _SlowModeUnit.seconds => 1,
    _SlowModeUnit.minutes => 60,
    _SlowModeUnit.hours => 3600,
  };

  int get _maximumValue => 21600 ~/ _unitMultiplier;

  int? get _seconds {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1 || value > _maximumValue) return null;
    return value * _unitMultiplier;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoAlertDialog(
    title: const Text('Своё значение'),
    content: Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoTextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            placeholder: 'Введите число',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          CupertinoSlidingSegmentedControl<_SlowModeUnit>(
            groupValue: _unit,
            children: const {
              _SlowModeUnit.seconds: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text('сек'),
              ),
              _SlowModeUnit.minutes: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text('мин'),
              ),
              _SlowModeUnit.hours: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text('часы'),
              ),
            },
            onValueChanged: (unit) {
              if (unit != null) setState(() => _unit = unit);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'От 1 секунды до 6 часов',
            style: TextStyle(color: AppColors.greyple, fontSize: 12),
          ),
        ],
      ),
    ),
    actions: [
      CupertinoDialogAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: _seconds == null
            ? null
            : () => Navigator.of(context).pop(_seconds),
        child: const Text('Применить'),
      ),
    ],
  );
}
