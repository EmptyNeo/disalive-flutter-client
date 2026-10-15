import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/role_members/bloc/role_members_bloc.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_member_tile.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_search_field.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddRoleMembersScreen extends StatefulWidget {
  const AddRoleMembersScreen({
    super.key,
    required this.role,
    required this.entityName,
    required this.membersBloc,
  });

  final RoleMember role;
  final String entityName;
  final MembersBloc membersBloc;

  static Future<void> open(
    BuildContext context, {
    required RoleMember role,
    required String entityName,
    required MembersBloc membersBloc,
  }) {
    final rolesBloc = context.read<RoleMembersBloc>();
    return SwipeToDismissRoute.push(
      context,
      (_) => BlocProvider.value(
        value: rolesBloc,
        child: AddRoleMembersScreen(
          role: role,
          entityName: entityName,
          membersBloc: membersBloc,
        ),
      ),
    );
  }

  @override
  State<AddRoleMembersScreen> createState() => _AddRoleMembersScreenState();
}

class _AddRoleMembersScreenState extends State<AddRoleMembersScreen> {
  final Set<int> _selected = {};
  String _query = '';
  bool _assigning = false;

  Future<void> _assign() async {
    if (_selected.isEmpty || _assigning) return;
    setState(() => _assigning = true);
    final bloc = context.read<RoleMembersBloc>();
    final result = await bloc.assignRole(widget.role.id!, _selected.toList());
    if (!mounted) return;
    setState(() => _assigning = false);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (success) {
        if (!success) return;
        final state = widget.membersBloc.state;
        if (state is MembersLoaded) {
          final updated = state.members
              .where((member) => _selected.contains(member.fkUser))
              .map(
                (member) => Member.fromMap({
                  ...member.toMap(),
                  'fkRole': widget.role.id,
                  'role': widget.role.toMap(),
                }),
              )
              .toList();
          widget.membersBloc.add(
            MemberUpdatedEvent(
              entityId: bloc.entityId,
              entityType: bloc.entityType,
              updatedMembers: updated,
            ),
          );
        }
        Navigator.of(context).maybePop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RoleMembersBloc>();
    final subtitle =
        '${widget.entityName} · ${bloc.entityType == EntityType.server ? 'Сервер' : 'Группа'}';
    return RoleScreenShell(
      title: 'Добавить участников',
      subtitle: subtitle,
      actionTitle: 'Назначить роль',
      onAction: _assign,
      actionEnabled: _selected.isNotEmpty && !_assigning,
      actionLoading: _assigning,
      child: Column(
        children: [
          RoleSearchField(
            placeholder: 'Поиск участников',
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          Expanded(
            child: BlocBuilder<MembersBloc, MembersState>(
              bloc: widget.membersBloc,
              builder: (context, state) {
                if (state is MembersLoading || state is MembersInitial) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (state is MembersFailure) {
                  return Center(
                    child: Text(
                      state.message,
                      style: TextStyle(color: AppColors.greyple),
                    ),
                  );
                }
                final members = (state as MembersLoaded).members
                    .where(
                      (member) =>
                          member.fkUser != null &&
                          member.fkRole != widget.role.id,
                    )
                    .where((member) {
                      final user = member.user;
                      return (user?.getDisplayName ?? '')
                              .toLowerCase()
                              .contains(_query) ||
                          (user?.username ?? '').toLowerCase().contains(_query);
                    })
                    .toList();
                if (members.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty
                          ? 'Нет участников для назначения'
                          : 'Участники не найдены',
                      style: TextStyle(color: AppColors.greyple),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final userId = member.fkUser!;
                    return RoleMemberTile(
                      member: member,
                      selected: _selected.contains(userId),
                      onTap: () => setState(() {
                        if (!_selected.add(userId)) _selected.remove(userId);
                      }),
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
