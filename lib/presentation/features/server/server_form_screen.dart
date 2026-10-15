import 'dart:io';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/app_selection_sheet.dart';
import 'package:disalive/presentation/widgets/media_picker_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/screens/avatar_crop_screen.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServerFormScreen extends StatefulWidget {
  const ServerFormScreen({super.key, this.server});

  final Server? server;

  static Future<Server?> open(BuildContext context, {Server? server}) {
    final serversBloc = context.read<ServersBloc>();
    return SwipeToDismissRoute.push<Server>(
      context,
      (_) => BlocProvider.value(
        value: serversBloc,
        child: ServerFormScreen(server: server),
      ),
    );
  }

  @override
  State<ServerFormScreen> createState() => _ServerFormScreenState();
}

class _ServerFormScreenState extends State<ServerFormScreen> {
  late final TextEditingController _nameController;
  late ServerType _category;
  late bool _canInvite;
  late bool _isPrivate;
  File? _avatar;
  bool _submitting = false;

  bool get _isEditing => widget.server != null;

  String? get _currentAvatarUrl {
    final path = widget.server?.pathAvatar;
    if (path == null || path.isEmpty) return null;
    final transformed = Domain.transformUrl(path);
    final uri = Uri.tryParse(transformed);
    if (uri == null) return null;
    return uri.hasScheme
        ? transformed
        : Uri.parse(Domain.imageDomain).resolve(transformed).toString();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server?.name ?? '')
      ..addListener(() => setState(() {}));
    _category = widget.server?.category ?? ServerType.none;
    _canInvite = (widget.server?.canInvite ?? 1) == 1;
    _isPrivate = widget.server?.isPrivate ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final files = await MediaPickerBottomSheet.open(
      context: context,
      onlyInitialType: true,
    );
    if (!mounted || files == null || files.isEmpty) return;
    final cropped = await AvatarCropScreen.open(context, file: files.first);
    if (!mounted || cropped == null) return;
    setState(() => _avatar = cropped);
  }

  Future<void> _chooseCategory() async {
    final selected = await AppSelectionSheet.show<ServerType>(
      context,
      title: 'Категория сервера',
      selectedValue: _category,
      options: [
        for (final type in ServerType.values)
          AppSelectionOption(
            value: type,
            label: type.label,
            icon: _categoryIcon(type),
          ),
      ],
    );
    if (mounted && selected != null) setState(() => _category = selected);
  }

  IconData _categoryIcon(ServerType type) => switch (type) {
    ServerType.none => CupertinoIcons.square_grid_2x2,
    ServerType.games => CupertinoIcons.game_controller,
    ServerType.music => CupertinoIcons.music_note_2,
    ServerType.entertainment => CupertinoIcons.film,
    ServerType.scienceAndTechnology => CupertinoIcons.gear,
    ServerType.education => CupertinoIcons.book,
    ServerType.sports => CupertinoIcons.sportscourt,
  };

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final repository = sl<ServerRepository>();
    final result = _isEditing
        ? await repository.update(
            widget.server!.id!,
            name,
            canInvite: _canInvite ? 1 : 0,
            isPrivate: _isPrivate ? 1 : 0,
            category: _category,
            avatar: _avatar,
          )
        : await repository.create(
            name,
            canInvite: _canInvite ? 1 : 0,
            isPrivate: _isPrivate ? 1 : 0,
            category: _category,
            avatar: _avatar,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (server) {
        context.read<ServersBloc>().add(ServerUpserted(server.toMap()));
        Navigator.of(context).pop(server);
      },
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: TextStyle(
      color: AppColors.greyple,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _setting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Key key,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: AppColors.white, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.greyple, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(key: key, value: value, onChanged: onChanged),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => RoleScreenShell(
    title: _isEditing ? 'Редактировать сервер' : 'Создать сервер',
    subtitle: _isEditing ? (widget.server?.name ?? 'Сервер') : 'Новый сервер',
    actionTitle: _isEditing ? 'Сохранить' : 'Создать сервер',
    onAction: _submit,
    actionEnabled: _nameController.text.trim().isNotEmpty && !_submitting,
    actionLoading: _submitting,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Center(
          child: CupertinoButton(
            key: const ValueKey('server_avatar_picker'),
            padding: EdgeInsets.zero,
            onPressed: _pickAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                BuildAvatar(
                  file: _avatar,
                  url: _avatar == null ? _currentAvatarUrl : null,
                  isGroup: true,
                  wh: 88,
                  size: 42,
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.actionGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.pencil,
                      size: 17,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Название сервера'),
        const SizedBox(height: 8),
        CupertinoTextField(
          key: const ValueKey('server_name_field'),
          controller: _nameController,
          maxLength: 30,
          placeholder: 'Название сервера',
          padding: const EdgeInsets.all(14),
          style: TextStyle(color: AppColors.white),
          decoration: BoxDecoration(
            color: AppColors.actionGrey,
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        const SizedBox(height: 22),
        _sectionTitle('Категория сервера'),
        const SizedBox(height: 8),
        CupertinoButton(
          key: const ValueKey('server_category_picker'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          color: AppColors.actionGrey,
          borderRadius: BorderRadius.circular(13),
          onPressed: _chooseCategory,
          child: Row(
            children: [
              Icon(_categoryIcon(_category), color: AppColors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _category.label,
                  style: TextStyle(color: AppColors.white),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                color: AppColors.greyple,
                size: 17,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _setting(
          key: const ValueKey('server_can_invite_switch'),
          title: 'Разрешить приглашения пользователей на сервер',
          subtitle:
              'Разрешите участникам приглашать других пользователей на этот сервер',
          value: _canInvite,
          onChanged: (value) => setState(() => _canInvite = value),
        ),
        _setting(
          key: const ValueKey('server_private_switch'),
          title: 'Приватный сервер',
          subtitle: 'В ваш сервер можно будет зайти только по приглашению',
          value: _isPrivate,
          onChanged: (value) => setState(() => _isPrivate = value),
        ),
      ],
    ),
  );
}
