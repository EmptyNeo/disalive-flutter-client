import 'dart:io';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/media_picker_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/screens/avatar_crop_screen.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';

class EditGroupScreen extends StatefulWidget {
  const EditGroupScreen({super.key, required this.chat});

  final Chat chat;

  static Future<void> open(BuildContext context, Chat chat) {
    return SwipeToDismissRoute.push(
      context,
      (context) => EditGroupScreen(chat: chat),
    );
  }

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  static const double _avatarSize = 96;

  late final String _initialName;
  late final TextEditingController _nameController;

  File? _selectedAvatarFile;
  bool _isAvatarDeleted = false;
  bool _isSaving = false;
  String defaultUrlImage = "/resources/DefaultGroupImage.png";

  final ValueNotifier<bool> _hasChanges = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initialName = widget.chat.name;
    _nameController = TextEditingController(text: _initialName);
    _nameController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldsChanged);
    _nameController.dispose();
    _hasChanges.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    final hasAvatarChange = _selectedAvatarFile != null || _isAvatarDeleted;
    final hasNameChange = _nameController.text.trim() != _initialName.trim();
    final changed = hasAvatarChange || hasNameChange;

    if (_hasChanges.value != changed) {
      _hasChanges.value = changed;
    }
  }

  void _resetChanges() {
    setState(() {
      _selectedAvatarFile = null;
      _isAvatarDeleted = false;
      _nameController.text = _initialName;
    });
    _onFieldsChanged();
  }

  Future<void> _pickAvatar() async {
    final files = await MediaPickerBottomSheet.open(
      context: context,
      onlyInitialType: true,
    );
    if (files == null || files.isEmpty) return;
    if (!mounted) return;

    final croppedFile = await AvatarCropScreen.open(context, file: files.first);

    setState(() {
      _selectedAvatarFile = croppedFile;
      _isAvatarDeleted = false;
    });
    _onFieldsChanged();
  }

  Future<void> _onSavePressed() async {
    if (_isSaving || !_hasChanges.value) return;

    setState(() => _isSaving = true);

    final result = await sl<ChatRepository>().update(
      widget.chat.id,
      _selectedAvatarFile,
      _nameController.text.trim(),
      _isAvatarDeleted,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => CustomToast.show(context: context, message: failure.message),
      (_) => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAvatarPicker(),
                                const SizedBox(height: 20),
                                _buildNameField(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 88),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildSaveButton(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Редактировать группу',
            style: AppText.highTextStyle.copyWith(
              color: AppColors.white,
              fontSize: 18,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _hasChanges,
            builder: (context, hasChanges, _) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: hasChanges ? _resetChanges : null,
                child: Icon(
                  CupertinoIcons.refresh,
                  size: 16,
                  color: hasChanges ? AppColors.white : AppColors.greyple,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    final bool showDeleteButton =
        !_isAvatarDeleted &&
        (_selectedAvatarFile != null ||
            widget.chat.urlAvatar != defaultUrlImage);

    return GestureDetector(
      onTap: _pickAvatar,
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: _isAvatarDeleted
                  ? BuildAvatar(
                      url: defaultUrlImage,
                      isGroup: widget.chat.isGroup,
                      wh: _avatarSize,
                      size: _avatarSize * 0.4,
                    )
                  : (_selectedAvatarFile != null
                        ? Image.file(
                            _selectedAvatarFile!,
                            width: _avatarSize,
                            height: _avatarSize,
                            fit: BoxFit.cover,
                          )
                        : BuildAvatar(
                            url: widget.chat.urlAvatar,
                            isGroup: widget.chat.isGroup,
                            wh: _avatarSize,
                            size: _avatarSize * 0.4,
                          )),
            ),
            if (showDeleteButton)
              Positioned(
                left: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatarFile = null;
                      _isAvatarDeleted = true;
                    });
                    _onFieldsChanged();
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.errorRed,
                      border: Border.all(
                        color: AppColors.mainBackground,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.trash,
                      size: 14,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),

            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blurple,
                  border: Border.all(color: AppColors.mainBackground, width: 3),
                ),
                child: const Icon(
                  CupertinoIcons.pencil,
                  size: 14,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
        ),
        child: CupertinoTextField(
          controller: _nameController,
          textAlign: TextAlign.start,
          placeholder: 'Название группы',
          placeholderStyle: TextStyle(color: AppColors.greyple, fontSize: 15),
          style: TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: const BoxDecoration(),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ValueListenableBuilder<bool>(
        valueListenable: _hasChanges,
        builder: (context, hasChanges, _) {
          final canSave = hasChanges && !_isSaving;

          return GestureDetector(
            onTap: canSave ? _onSavePressed : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canSave
                    ? AppColors.blurple
                    : AppColors.blurple.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isSaving
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : Text(
                      'Сохранить',
                      style: TextStyle(
                        color: AppColors.onBlurple,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
