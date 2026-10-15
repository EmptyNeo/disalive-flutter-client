import 'dart:async';
import 'dart:io';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/models/ui/font_option.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/profile/widgets/edit_screen/live_preview_delegate.dart';
import 'package:disalive/presentation/features/profile/widgets/edit_screen/section_divider.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/ui/color_hex_extension.dart';
import 'package:disalive/presentation/utils/ui/color_service.dart';
import 'package:disalive/presentation/utils/ui/max_lines_input_formatter.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:disalive/presentation/widgets/media_picker_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/screens/avatar_crop_screen.dart';
import 'package:disalive/presentation/widgets/screens/banner_crop_screen.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:photo_manager/photo_manager.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  static Future<void> open(BuildContext context, UserModel user) {
    ProfileBloc profileBloc = context.read<ProfileBloc>();
    return SwipeToDismissRoute.push(
      context,
      (context) => BlocProvider.value(
        value: profileBloc,
        child: EditProfileScreen(user: user),
      ),
    );
  }

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isSaving = false;
  late StreamSubscription<Failure> _errorSubscription;

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _aboutMeCtrl;
  late final TextEditingController _myThinkCtrl;

  File? _newAvatarFile;
  bool _isAvatarDeleted = false;
  File? _newBannerFile;
  bool _isBannerDeleted = false;

  late Color _originalBannerColor;
  late Color _bannerColor;
  late Color _originalMainProfileColor;
  late Color _mainProfileColor;
  late Color _originalAdditionalProfileColor;
  late Color _additionalProfileColor;

  String _selectedFont = 'Стандартный';
  final List<FontOption> _availableFonts = [
    FontOption('Стандартный', ''),
    FontOption('Inter', 'Inter'),
    FontOption('Roboto', 'Roboto'),
    FontOption('Poppins', 'Poppins'),
    FontOption('Playfair Display', 'Playfair Display'),
    FontOption('Montserrat', 'Montserrat'),
    FontOption('Raleway', 'Raleway'),
    FontOption('Ubuntu', 'Ubuntu'),
    FontOption('Oswald', 'Oswald'),
    FontOption('Georgia', 'Georgia'),
    FontOption('Courier New', 'Courier New'),
    FontOption('Times New Roman', 'Times New Roman'),
    FontOption('Comic Sans MS', 'Comic Sans MS'),
    FontOption('Trebuchet MS', 'Trebuchet MS'),
    FontOption('Arial', 'Arial'),
    FontOption('Impact', 'Impact'),
    FontOption('Sakura', 'Fredoka'),
    FontOption('Medieval', 'Cinzel'),
    FontOption('8Bit', 'BitCustom'),
    FontOption('Vampyre', 'Tangerine'),
    FontOption('Buka Bird', 'Buka Bird'),
    FontOption('Buse', 'Buse'),
    FontOption('Correction Tape', 'Correction Tape'),
    FontOption('Third Street (Только англ. буквы)', 'Third Street'),
    FontOption('Rhombic', 'Rhombic'),
    FontOption('Kom Post', 'Kom Post'),
    FontOption('Blast Hollow', 'Blast Hollow'),
  ];

  int _selectedBadgeIndex = 0;
  late int _originalBadgeIndex;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _usernameCtrl = TextEditingController(text: widget.user.username ?? '');
    _aboutMeCtrl = TextEditingController(text: widget.user.aboutMe ?? '');
    _myThinkCtrl = TextEditingController(text: widget.user.myThink ?? '');

    _originalBannerColor = ColorService.parseColor(widget.user.bannerColor);
    _bannerColor = _originalBannerColor;

    _originalMainProfileColor = ColorService.parseColor(
      widget.user.bageMainColor,
    );
    _mainProfileColor = _originalMainProfileColor;

    _originalAdditionalProfileColor = ColorService.parseColor(
      widget.user.bageAdditionalColor,
    );
    _additionalProfileColor = _originalAdditionalProfileColor;

    _selectedFont = widget.user.fontUsername ?? '';

    _originalBadgeIndex = -1;
    _selectedBadgeIndex = -1;

    if (widget.user.badges != null && widget.user.badges!.isNotEmpty) {
      if (widget.user.mainBadge != null) {
        _originalBadgeIndex = widget.user.badges!.indexWhere(
          (b) => b.badge?.id == widget.user.mainBadge!.id,
        );
        _selectedBadgeIndex = _originalBadgeIndex;
      }
    }
    _errorSubscription = context.read<ProfileBloc>().errorStream.listen((
      failure,
    ) {
      if (!mounted) return;
      CustomToast.open(
        context: context,
        icon: CupertinoIcons.clear,
        color: AppColors.errorRed,
        message: failure.message ?? 'Не удалось сохранить изменения',
      );
      setState(() => _isSaving = false); // Разблокируем кнопку
    });
  }

  @override
  void dispose() {
    _errorSubscription.cancel();
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _aboutMeCtrl.dispose();
    _myThinkCtrl.dispose();
    super.dispose();
  }

  int? get _currentSelectedBadgeId {
    if (_selectedBadgeIndex == -1) {
      return null;
    }

    if (widget.user.badges != null &&
        _selectedBadgeIndex >= 0 &&
        _selectedBadgeIndex < widget.user.badges!.length) {
      return widget.user.badges![_selectedBadgeIndex].badge?.id;
    }

    return null;
  }

  bool get _hasChanges {
    return _displayNameCtrl.text != (widget.user.displayName ?? '') ||
        _usernameCtrl.text != (widget.user.username ?? '') ||
        _aboutMeCtrl.text != (widget.user.aboutMe ?? '') ||
        _myThinkCtrl.text != (widget.user.myThink ?? '') ||
        _isAvatarDeleted ||
        _isBannerDeleted ||
        _newAvatarFile != null ||
        _newBannerFile != null ||
        _bannerColor.toARGB32() != _originalBannerColor.toARGB32() ||
        _mainProfileColor.toARGB32() != _originalMainProfileColor.toARGB32() ||
        _additionalProfileColor.toARGB32() !=
            _originalAdditionalProfileColor.toARGB32() ||
        _selectedFont != (widget.user.fontUsername ?? '') ||
        _currentSelectedBadgeId != widget.user.fkMainBadge;
  }

  Future<void> _pickMedia(bool isAvatar) async {
    final files = await MediaPickerBottomSheet.open(
      context: context,
      type: RequestType.image,
      onlyInitialType: true,
      allowMultiple: false,
    );

    if (files != null && files.isNotEmpty && mounted) {
      if (isAvatar) {
        final croppedFile = await AvatarCropScreen.open(
          context,
          file: files.first,
        );

        setState(() {
          _newAvatarFile = croppedFile;
          _isAvatarDeleted = false;
        });
      } else {
        final croppedFile = await BannerCropModal.open(
          context,
          file: files.first,
        );

        setState(() {
          _newBannerFile = croppedFile;
          _isBannerDeleted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aboutMeHeight = _calculateAboutMeHeight(context);

    final previewBadge =
        (_selectedBadgeIndex >= 0 &&
            widget.user.badges != null &&
            _selectedBadgeIndex < widget.user.badges!.length)
        ? widget.user.badges![_selectedBadgeIndex].badge
        : null;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 6.0,
                ),
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
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: LivePreviewDelegate(
                            displayName: _displayNameCtrl.text,
                            username: _usernameCtrl.text,
                            aboutMe: _aboutMeCtrl.text,
                            myThink: _myThinkCtrl.text,
                            avatarFile: _isAvatarDeleted
                                ? null
                                : _newAvatarFile,
                            avatarUrl: _isAvatarDeleted
                                ? null
                                : widget.user.urlAvatar,
                            bannerFile: _isBannerDeleted
                                ? null
                                : _newBannerFile,
                            bannerUrl: _isBannerDeleted
                                ? null
                                : widget.user.pathBanner,
                            bannerColor: _bannerColor,
                            mainColor: _mainProfileColor,
                            additionalColor: _additionalProfileColor,
                            badge: previewBadge,
                            aboutMeHeight: aboutMeHeight,
                            onAvatarTap: () => _pickMedia(true),
                            onBannerTap: () => _pickMedia(false),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  label: 'Отображаемое имя',
                                  controller: _displayNameCtrl,
                                  placeholder: 'Имя',
                                  maxLength: 30,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Имя пользователя',
                                  controller: _usernameCtrl,
                                  placeholder: 'username',
                                  prefix: '@',
                                  maxLength: 20,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'О себе',
                                  controller: _aboutMeCtrl,
                                  placeholder: 'Расскажите о себе',
                                  maxLines: 4,
                                  maxLength: 200,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Мои мысли',
                                  controller: _myThinkCtrl,
                                  placeholder: 'Что у вас на уме?',
                                  maxLines: 2,
                                  maxLength: 90,
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown(
                                  label: 'Отображаемый значок',
                                  value: previewBadge?.name ?? 'Не выбран',
                                  onTap: _showBadgePicker,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: SectionDivider()),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('АВАТАР', style: _sectionTitleStyle()),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        title: 'Изменить',
                                        icon: CupertinoIcons.photo,
                                        color: AppColors.blurple,
                                        onTap: () => _pickMedia(true),
                                      ),
                                    ),
                                    if (!_isAvatarDeleted &&
                                        (widget.user.urlAvatar.isNotEmpty ==
                                                true ||
                                            _newAvatarFile != null)) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildActionButton(
                                          title: 'Удалить',
                                          icon: CupertinoIcons.trash,
                                          color: AppColors.errorRed,
                                          onTap: () => setState(() {
                                            _newAvatarFile = null;
                                            _isAvatarDeleted = true;
                                          }),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('БАННЕР', style: _sectionTitleStyle()),
                                const SizedBox(height: 12),
                                _buildColorPickerField(
                                  label: 'Цвет фона (если нет изображения)',
                                  selectedColor: _bannerColor,
                                  onColorSelected: (c) =>
                                      setState(() => _bannerColor = c),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        title: 'Изменить',
                                        icon: CupertinoIcons.photo_on_rectangle,
                                        color: AppColors.blurple,
                                        onTap: () => _pickMedia(false),
                                      ),
                                    ),
                                    if (!_isBannerDeleted &&
                                        (widget.user.pathBanner?.isNotEmpty ==
                                                true ||
                                            _newBannerFile != null)) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildActionButton(
                                          title: 'Удалить',
                                          icon: CupertinoIcons.trash,
                                          color: AppColors.errorRed,
                                          onTap: () => setState(() {
                                            _newBannerFile = null;
                                            _isBannerDeleted = true;
                                          }),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Рекомендуется 350×150 и больше. Максимум 10 МБ.',
                                  style: AppText.lowTextStyle.copyWith(
                                    color: AppColors.greyple,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SectionDivider()),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'СТИЛЬ ПРОФИЛЯ',
                                  style: _sectionTitleStyle(),
                                ),
                                const SizedBox(height: 12),
                                _buildDropdown(
                                  label: 'Шрифт имени пользователя',
                                  value: _getFontLabel(_selectedFont),
                                  onTap: _showFontPicker,
                                ),
                                const SizedBox(height: 16),
                                _buildColorPickerField(
                                  label: 'Основной цвет профиля',
                                  selectedColor: _mainProfileColor,
                                  onColorSelected: (c) =>
                                      setState(() => _mainProfileColor = c),
                                ),
                                const SizedBox(height: 16),
                                _buildColorPickerField(
                                  label: 'Дополнительный цвет профиля',
                                  selectedColor: _additionalProfileColor,
                                  onColorSelected: (c) => setState(
                                    () => _additionalProfileColor = c,
                                  ),
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const CustomBackButton(positioned: 15),
              BlocListener<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (_isSaving && state is ProfileLoaded) {
                    if (!state.loadingFields.contains('save_profile')) {
                      setState(() => _isSaving = false);
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    final isLoading =
                        state is ProfileLoaded &&
                        state.loadingFields.contains('save_profile');

                    return Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: (_hasChanges && !_isSaving) ? 1.0 : 0.5,
                        child: CupertinoButton.filled(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          borderRadius: BorderRadius.circular(16),
                          onPressed: (_hasChanges && !_isSaving)
                              ? _saveProfile
                              : null,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  ),
                                )
                              : const Text(
                                  'Сохранить изменения',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() {
    if (!_hasChanges || _isSaving) return;

    _isSaving = true; // 🎯 Блокируем повторные нажатия

    // 1. Создаем копию пользователя с обновленными текстовыми и цветовыми данными
    final updateUser = widget.user.copyWith(
      displayName: _displayNameCtrl.text,
      username: _usernameCtrl.text,
      aboutMe: _aboutMeCtrl.text,
      myThink: _myThinkCtrl.text,
      fontUsername: _selectedFont,
      bageMainColor: _mainProfileColor.toHex(),
      bageAdditionalColor: _additionalProfileColor.toHex(),
      bannerColor: _bannerColor.toHex(),
      fkMainBadge: _currentSelectedBadgeId,
      fileAvatar: _newAvatarFile,
      fileBanner: _newBannerFile,
      deleteAvatar: _isAvatarDeleted,
      deleteBanner: _isBannerDeleted,
    );

    // 3. Отправляем событие в Bloc с флагом загрузки 'save_profile'
    context.read<ProfileBloc>().add(
      UpdateProfile(updateUser, loadingField: 'save_profile'),
    );
  }

  void _showBadgePicker() {
    final badges = widget.user.badges;
    if (badges == null) {
      _showToast("У вас пока нет значков");
      return;
    }

    if (badges.isEmpty) {
      _showToast("У вас пока нет значков");
      return;
    }
    final List<ActionItem> actions = [];

    actions.add(
      ActionItem(
        icon: CupertinoIcons.xmark,
        label: 'Без значка',
        color: AppColors.greyple,
        onTap: () {
          setState(() {
            _selectedBadgeIndex = -1;
          });
        },
      ),
    );

    // 🎯 2. Добавляем все доступные значки пользователя
    if (widget.user.badges != null) {
      for (int i = 0; i < widget.user.badges!.length; i++) {
        final badge = widget.user.badges![i].badge;
        if (badge != null) {
          actions.add(
            ActionItem(
              icon: CupertinoIcons.star_fill,
              label: badge.name ?? 'Без названия',
              color: AppColors.white,
              onTap: () {
                setState(() {
                  _selectedBadgeIndex = i;
                });
              },
            ),
          );
        }
      }
    }

    ActionBottomSheet.show(
      context,
      title: 'Выберите отображаемый значок',
      actions: actions,
    );
  }

  void _showFontPicker() {
    // 🎯 Генерируем список действий из наших шрифтов
    final List<ActionItem> actions = _availableFonts.map((font) {
      return ActionItem(
        icon: CupertinoIcons.textformat,
        label: font.label,
        color: AppColors.white,
        onTap: () {
          setState(() {
            _selectedFont = font.value;
          });
        },
      );
    }).toList();

    ActionBottomSheet.show(context, title: 'Выберите шрифт', actions: actions);
  }

  String _getFontLabel(String value) {
    final font = _availableFonts.firstWhere(
      (f) => f.value == value,
      orElse: () => const FontOption('Стандартный', ''),
    );
    return font.label;
  }

  void _showColorPicker(
    BuildContext context,
    Color currentColor,
    ValueChanged<Color> onColorSelected,
  ) {
    Color tempColor = currentColor;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.mainBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Выберите цвет',
              style: AppText.highTextStyle.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 16),

            // 🎯 ИСПРАВЛЕНИЕ: Добавляем Padding и немного уменьшаем высоту области
            SizedBox(
              height: 300,
              child: ColorPicker(
                pickerColor: tempColor,
                onColorChanged: (color) => tempColor = color,
                pickerAreaHeightPercent: 0.7,
                displayThumbColor: true,
                enableAlpha: false,
                labelTypes: const [],
                pickerAreaBorderRadius: BorderRadius.circular(8),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    color: AppColors.actionGrey,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      onColorSelected(tempColor);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Выбрать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    CustomToast.open(
      context: context,
      icon: CupertinoIcons.clear,
      message: message,
    );
  }

  TextStyle _sectionTitleStyle() => AppText.lowTextStyle.copyWith(
    color: AppColors.greyple,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required int maxLength,
    String? prefix,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppText.mediumTextStyle.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "${controller.text.length}/$maxLength",
              style: AppText.lowTextStyle.copyWith(color: AppColors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: maxLines > 1
              ? [MaxLinesInputFormatter(maxLines)]
              : null,
          onChanged: (_) => setState(() {}),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.actionGrey,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          prefix: prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    prefix,
                    style: TextStyle(color: AppColors.greyple),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.mediumTextStyle.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.actionGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.white,
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  color: AppColors.greyple,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPickerField({
    required String label,
    required Color selectedColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.mediumTextStyle.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () =>
              _showColorPicker(context, selectedColor, onColorSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.actionGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              children: [
                // 🎯 Визуальное отображение текущего цвета
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Выбрать цвет',
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.greyple,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 10),
      borderRadius: BorderRadius.circular(8),
      color: color.withValues(alpha: 0.15),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: AppText.mediumTextStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAboutMeHeight(BuildContext context) {
    if (_aboutMeCtrl.text.isEmpty) return 0;

    // 🎯 Стиль должен ТОЧНО совпадать с тем, что в LivePreviewDelegate
    final textSpan = TextSpan(
      text: _aboutMeCtrl.text,
      style: AppText.lowTextStyle.copyWith(
        color: AppColors.white.withValues(alpha: 0.95),
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );

    final screenWidth = MediaQuery.of(context).size.width;

    // 🎯 Расчет доступной ширины:
    // 16 (left Positioned) + 16 (right Positioned) + 8 (padding left) + 8 (padding right) = 48
    final availableWidth = screenWidth - 48;

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 4,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableWidth);

    // 🎯 Расчет итоговой высоты:
    // 12 (SizedBox сверху) + 8 (padding top) + 8 (padding bottom) + 2 (небольшой запас на рендеринг шрифтов) = 30
    return textPainter.height + 30;
  }
}
