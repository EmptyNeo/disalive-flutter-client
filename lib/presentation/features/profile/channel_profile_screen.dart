import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/members/widgets/members_list.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChannelProfileScreen extends StatefulWidget {
  const ChannelProfileScreen({super.key, required this.chat, this.server});

  final Chat chat;
  final Server? server;

  @override
  State<ChannelProfileScreen> createState() => _ChannelProfileScreenState();
}

class _ChannelProfileScreenState extends State<ChannelProfileScreen> {
  int get _entityId => widget.server?.id ?? widget.chat.id;

  EntityType get _entityType =>
      widget.server?.id == null ? EntityType.chat : EntityType.server;

  @override
  void initState() {
    super.initState();
    context.read<MembersBloc>().add(
      GetMembers(entityId: _entityId, entityType: _entityType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.server;
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
                  CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 56)),
                      MembersList(
                        entityId: _entityId,
                        entityType: _entityType,
                        entityName: server?.name ?? widget.chat.name,
                        initialMemberCount:
                            server?.memberCount ?? widget.chat.memberCount,
                        canManageMembers:
                            server?.isServerOwner == true ||
                            server?.hasPermission(
                                  ServerPermissions.manageMembers,
                                ) ==
                                true,
                        canManageRoles:
                            server?.isServerOwner == true ||
                            server?.hasPermission(
                                  ServerPermissions.manageRoles,
                                ) ==
                                true,
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                  const CustomBackButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
