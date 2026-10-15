import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/presentation/features/role_members/bloc/role_members_bloc.dart';
import 'package:disalive/presentation/features/role_members/role_edit_screen.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_item.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_search_field.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleMembersScreen extends StatefulWidget {
  const RoleMembersScreen({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.entityName,
  });

  final int entityId;
  final EntityType entityType;
  final String entityName;

  static Future<void> open(
    BuildContext context, {
    required int entityId,
    required EntityType entityType,
    required String entityName,
  }) {
    final bloc = sl<RoleMembersBloc>(param1: entityId, param2: entityType)
      ..add(const GetRoleMembers());
    return SwipeToDismissRoute.push(
      context,
      (_) => BlocProvider.value(
        value: bloc,
        child: RoleMembersScreen(
          entityId: entityId,
          entityType: entityType,
          entityName: entityName,
        ),
      ),
    ).whenComplete(bloc.close);
  }

  @override
  State<RoleMembersScreen> createState() => _RoleMembersScreenState();
}

class _RoleMembersScreenState extends State<RoleMembersScreen> {
  String _query = '';
  bool _creating = false;
  int? _deletingId;

  String get _subtitle =>
      '${widget.entityName} · ${widget.entityType == EntityType.server ? 'Сервер' : 'Группа'}';

  Future<void> _create() async {
    if (_creating) return;
    setState(() => _creating = true);
    final result = await context.read<RoleMembersBloc>().createRole();
    if (!mounted) return;
    setState(() => _creating = false);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (role) => _openRole(role),
    );
  }

  void _openRole(RoleMember role) {
    RoleEditScreen.open(context, role: role, entityName: widget.entityName);
  }

  Future<void> _delete(RoleMember role) async {
    if (role.id == null) return;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Удалить роль?',
      description:
          'Роль «${role.name?.isNotEmpty == true ? role.name : role.emoji}» будет удалена у всех участников.',
      confirmText: 'Удалить',
      isDestructive: true,
      icon: CupertinoIcons.trash,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingId = role.id);
    final result = await context.read<RoleMembersBloc>().deleteRole(role.id!);
    if (!mounted) return;
    setState(() => _deletingId = null);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleScreenShell(
      title: 'Управление ролями',
      subtitle: _subtitle,
      actionTitle: 'Создать роль',
      onAction: _create,
      actionEnabled: !_creating,
      actionLoading: _creating,
      child: Column(
        children: [
          RoleSearchField(
            placeholder: 'Поиск ролей',
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          Expanded(
            child: BlocBuilder<RoleMembersBloc, RoleMembersState>(
              builder: (context, state) {
                if (state is RoleMembersLoading ||
                    state is RoleMembersInitial) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (state is RoleMembersFailure) {
                  return Center(
                    child: CupertinoButton(
                      onPressed: () => context.read<RoleMembersBloc>().add(
                        const GetRoleMembers(),
                      ),
                      child: Text(
                        state.message,
                        style: TextStyle(color: AppColors.greyple),
                      ),
                    ),
                  );
                }
                final roles = (state as RoleMembersLoaded).roles
                    .where(
                      (role) =>
                          (role.name ?? '').toLowerCase().contains(_query) ||
                          (role.emoji ?? '').toLowerCase().contains(_query),
                    )
                    .toList();
                if (roles.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty ? 'Ролей пока нет' : 'Роли не найдены',
                      style: TextStyle(color: AppColors.greyple),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    return Opacity(
                      opacity: _deletingId == role.id ? 0.5 : 1,
                      child: RoleItem(
                        role: role,
                        onTap: () => _openRole(role),
                        onDelete: () => _delete(role),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
