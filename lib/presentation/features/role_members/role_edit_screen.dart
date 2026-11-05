import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/role_members/add_role_members_screen.dart';
import 'package:disalive/presentation/features/role_members/bloc/role_members_bloc.dart';
import 'package:disalive/presentation/features/role_members/role_permission_meta.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_emoji.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_emoji_picker.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_colored_text.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_member_tile.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_permission_tile.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_search_field.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleEditScreen extends StatefulWidget {
  const RoleEditScreen({
    super.key,
    required this.role,
    required this.entityName,
  });
  final RoleMember role;
  final String entityName;

  static Future<void> open(
    BuildContext context, {
    required RoleMember role,
    required String entityName,
  }) {
    final bloc = context.read<RoleMembersBloc>();
    return SwipeToDismissRoute.push(
      context,
      (_) => BlocProvider.value(
        value: bloc,
        child: RoleEditScreen(role: role, entityName: entityName),
      ),
    );
  }

  @override
  State<RoleEditScreen> createState() => _RoleEditScreenState();
}

class _RoleEditScreenState extends State<RoleEditScreen> {
  late RoleMember _role;
  late TextEditingController _nameController;
  late Map<String, bool> _permissions;
  late String? _emoji;
  late TextEditingController _colorController;
  late TextEditingController _gradientStartController;
  late TextEditingController _gradientEndController;
  late int _gradientAngle;
  int _colorMode = 0;
  late final MembersBloc _membersBloc;
  int _tab = 0;
  String _memberQuery = '';
  bool _saving = false;
  int? _unassigningId;

  RoleMembersBloc get _rolesBloc => context.read<RoleMembersBloc>();
  String get _subtitle =>
      '${widget.entityName} · ${_rolesBloc.entityType == EntityType.server ? 'Сервер' : 'Группа'}';

  @override
  void initState() {
    super.initState();
    _role = widget.role;
    _nameController = TextEditingController(text: _role.name ?? '')
      ..addListener(() => setState(() {}));
    _emoji = _role.emoji;
    _colorController = TextEditingController(text: _role.color ?? '');
    _gradientStartController = TextEditingController(
      text: _role.gradientStart ?? '',
    );
    _gradientEndController = TextEditingController(
      text: _role.gradientEnd ?? '',
    );
    _gradientAngle = _role.gradientAngle;
    _colorMode = _role.gradientStart != null && _role.gradientEnd != null
        ? 2
        : (_role.color != null ? 1 : 0);
    _permissions = normalizeRolePermissions(
      EntityType.fromString(_role.entityType),
      _role.permissions ?? {},
    );
    _membersBloc = sl<MembersBloc>()
      ..setupListeners()
      ..add(
        GetMembers(
          entityId: _role.entityId ?? context.read<RoleMembersBloc>().entityId,
          entityType: EntityType.fromString(_role.entityType),
        ),
      );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _gradientStartController.dispose();
    _gradientEndController.dispose();
    _membersBloc.close();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (_saving) return;
    if (name.isEmpty && (_emoji?.isEmpty ?? true)) {
      CustomToast.open(
        context: context,
        message: 'У роли должно быть имя или эмодзи',
      );
      return;
    }
    final color = _colorMode == 1
        ? _normalizedHex(_colorController.text)
        : null;
    final gradientStart = _colorMode == 2
        ? _normalizedHex(_gradientStartController.text)
        : null;
    final gradientEnd = _colorMode == 2
        ? _normalizedHex(_gradientEndController.text)
        : null;
    if ((_colorMode == 1 && color == null) ||
        (_colorMode == 2 && (gradientStart == null || gradientEnd == null))) {
      CustomToast.open(
        context: context,
        message: 'Введите цвет в формате HEX, например #7C5CFF',
      );
      return;
    }
    setState(() => _saving = true);
    final result = await _rolesBloc.updateRole(
      _role,
      name: name,
      emoji: _emoji,
      color: color,
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      gradientAngle: _gradientAngle,
      permissions: _permissions,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (role) => setState(() => _role = role),
    );
  }

  Future<void> _pickEmoji() async {
    final selected = await RoleEmojiPicker.show(context);
    if (selected != null && mounted) setState(() => _emoji = selected);
  }

  String? _normalizedHex(String value) {
    final hex = value.trim();
    return RegExp(r'^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$').hasMatch(hex)
        ? hex.toUpperCase()
        : null;
  }

  Future<void> _unassign(Member member) async {
    final userId = member.fkUser;
    final roleId = _role.id;
    if (userId == null || roleId == null || _unassigningId != null) return;
    final roleName = _role.name?.trim().isNotEmpty == true
        ? _role.name!.trim()
        : (_role.emoji?.trim().isNotEmpty == true
              ? _role.emoji!.trim()
              : 'Роль');
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Снять роль?',
      description:
          'Вы уверены, что хотите снять роль «$roleName» с участника ${member.user?.getDisplayName ?? 'Участник'}?',
      confirmText: 'Снять роль',
      isDestructive: true,
      icon: CupertinoIcons.minus_circle,
    );
    if (confirmed != true || !mounted || _unassigningId != null) return;
    setState(() => _unassigningId = userId);
    final result = await _rolesBloc.unassignRole(roleId, userId);
    if (!mounted) return;
    setState(() => _unassigningId = null);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (success) {
        if (success) {
          _membersBloc.add(
            MemberUpdatedEvent(
              entityId: _rolesBloc.entityId,
              entityType: _rolesBloc.entityType,
              updatedMembers: [
                Member.fromMap({
                  ...member.toMap(),
                  'fkRole': null,
                  'role': null,
                }),
              ],
            ),
          );
        }
      },
    );
  }

  void _openAddMembers() => AddRoleMembersScreen.open(
    context,
    role: _role,
    entityName: widget.entityName,
    membersBloc: _membersBloc,
  );

  @override
  Widget build(BuildContext context) {
    final roleName = _nameController.text.trim();
    return RoleScreenShell(
      title: roleName,
      titleSuffix: _emoji?.isNotEmpty == true
          ? RoleEmoji(_emoji, size: 21)
          : null,
      subtitle: _subtitle,
      actionTitle: _tab == 2 ? 'Назначить роль' : 'Сохранить',
      onAction: _tab == 2 ? _openAddMembers : _save,
      actionEnabled: !_saving,
      actionLoading: _saving,
      child: Column(
        children: [
          _tabs(),
          const SizedBox(height: 14),
          Expanded(
            child: switch (_tab) {
              0 => _appearance(),
              1 => _permissionList(),
              _ => _members(),
            },
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    const tabs = ['Внешний вид', 'Права доступа', 'Управлять участниками'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) => CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          color: _tab == index ? AppColors.blurple : AppColors.actionGrey,
          borderRadius: BorderRadius.circular(12),
          onPressed: () => setState(() => _tab = index),
          child: Text(
            tabs[index],
            style: TextStyle(
              color: _tab == index ? AppColors.onBlurple : AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _appearance() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    children: [
      Text(
        'Название роли',
        style: TextStyle(color: AppColors.greyple, fontSize: 13),
      ),
      const SizedBox(height: 8),
      CupertinoTextField(
        controller: _nameController,
        maxLength: 25,
        placeholder: 'Название роли',
        style: TextStyle(color: AppColors.white),
        decoration: BoxDecoration(
          color: AppColors.actionGrey,
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(14),
      ),
      const SizedBox(height: 22),
      Text(
        'Цвет ника',
        style: TextStyle(color: AppColors.greyple, fontSize: 13),
      ),
      const SizedBox(height: 8),
      CupertinoSlidingSegmentedControl<int>(
        groupValue: _colorMode,
        children: const {0: Text('Нет'), 1: Text('Цвет'), 2: Text('Градиент')},
        onValueChanged: (value) => setState(() => _colorMode = value ?? 0),
      ),
      if (_colorMode == 1) ...[
        const SizedBox(height: 10),
        _hexField(_colorController, 'Цвет HEX, например #7C5CFF'),
      ],
      if (_colorMode == 2) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _hexField(_gradientStartController, 'Начало #HEX')),
            const SizedBox(width: 8),
            Expanded(child: _hexField(_gradientEndController, 'Конец #HEX')),
          ],
        ),
        Row(
          children: [
            Text(
              'Угол: $_gradientAngle°',
              style: TextStyle(color: AppColors.greyple),
            ),
            Expanded(
              child: CupertinoSlider(
                min: 0,
                max: 360,
                divisions: 36,
                value: _gradientAngle.toDouble(),
                onChanged: (value) =>
                    setState(() => _gradientAngle = value.round()),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 22),
      Text('Эмодзи', style: TextStyle(color: AppColors.greyple, fontSize: 13)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.all(14),
                onPressed: _pickEmoji,
                child: Row(
                  children: [
                    if (_emoji?.isNotEmpty == true) ...[
                      IgnorePointer(child: RoleEmoji(_emoji)),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      _emoji?.isNotEmpty == true
                          ? 'Изменить эмодзи'
                          : 'Выбрать эмодзи',
                      style: TextStyle(color: AppColors.greyple),
                    ),
                  ],
                ),
              ),
            ),
            if (_emoji?.isNotEmpty == true)
              CupertinoButton(
                onPressed: () => setState(() => _emoji = null),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppColors.iconGrey,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      Text(
        'Предпросмотр',
        style: TextStyle(color: AppColors.greyple, fontSize: 13),
      ),
      const SizedBox(height: 9),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.shield_lefthalf_fill,
              color: AppColors.iconGrey,
              size: 21,
            ),
            const SizedBox(width: 11),
            if (_nameController.text.trim().isNotEmpty)
              Flexible(
                child: RoleColoredText(
                  text: _nameController.text.trim(),
                  role: _previewRole(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.white, fontSize: 15),
                ),
              ),
            if (_emoji?.isNotEmpty == true) ...[
              if (_nameController.text.trim().isNotEmpty)
                const SizedBox(width: 7),
              RoleEmoji(_emoji),
            ],
          ],
        ),
      ),
    ],
  );

  RoleMember _previewRole() => RoleMember(
    color: _colorMode == 1 ? _normalizedHex(_colorController.text) : null,
    gradientStart: _colorMode == 2
        ? _normalizedHex(_gradientStartController.text)
        : null,
    gradientEnd: _colorMode == 2
        ? _normalizedHex(_gradientEndController.text)
        : null,
    gradientAngle: _gradientAngle,
  );

  Widget _hexField(TextEditingController controller, String placeholder) =>
      CupertinoTextField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        maxLength: 7,
        placeholder: placeholder,
        style: TextStyle(color: AppColors.white),
        decoration: BoxDecoration(
          color: AppColors.actionGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        onChanged: (_) => setState(() {}),
      );

  Widget _permissionList() => ListView(
    children: [
      for (final meta in rolePermissionsFor(_rolesBloc.entityType))
        RolePermissionTile(
          meta: meta,
          value: _permissions[meta.key] ?? false,
          onChanged: (value) => setState(
            () => _permissions = changeRolePermission(
              _rolesBloc.entityType,
              _permissions,
              meta.key,
              value,
            ),
          ),
        ),
    ],
  );

  Widget _members() => Column(
    children: [
      RoleSearchField(
        placeholder: 'Поиск участников',
        onChanged: (value) =>
            setState(() => _memberQuery = value.trim().toLowerCase()),
      ),
      Expanded(
        child: BlocBuilder<MembersBloc, MembersState>(
          bloc: _membersBloc,
          builder: (context, state) {
            if (state is MembersLoading || state is MembersInitial) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (state is MembersFailure) {
              return Center(
                child: CupertinoButton(
                  onPressed: () => _membersBloc.add(
                    GetMembers(
                      entityId: _rolesBloc.entityId,
                      entityType: _rolesBloc.entityType,
                    ),
                  ),
                  child: Text(
                    state.message,
                    style: TextStyle(color: AppColors.greyple),
                  ),
                ),
              );
            }
            final members = (state as MembersLoaded).members
                .where((member) => member.fkRole == _role.id)
                .where((member) {
                  final user = member.user;
                  return (user?.getDisplayName ?? '').toLowerCase().contains(
                        _memberQuery,
                      ) ||
                      (user?.username ?? '').toLowerCase().contains(
                        _memberQuery,
                      );
                })
                .toList();
            if (members.isEmpty) {
              return Center(
                child: Text(
                  _memberQuery.isEmpty
                      ? 'У роли пока нет участников'
                      : 'Участники не найдены',
                  style: TextStyle(color: AppColors.greyple),
                ),
              );
            }
            return ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return Opacity(
                  opacity: _unassigningId == member.fkUser ? 0.5 : 1,
                  child: RoleMemberTile(
                    member: member,
                    onRemove: () => _unassign(member),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
