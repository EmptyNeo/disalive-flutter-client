import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/invites/widgets/server_invite_item.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/app_clipboard.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageServerInvitesScreen extends StatefulWidget {
  const ManageServerInvitesScreen({super.key, required this.server});

  final Server server;

  static Future<void> open(BuildContext context, {required Server server}) {
    final invitesBloc = context.read<InvitesBloc>();
    return SwipeToDismissRoute.push(
      context,
      (_) => BlocProvider.value(
        value: invitesBloc,
        child: ManageServerInvitesScreen(server: server),
      ),
    );
  }

  @override
  State<ManageServerInvitesScreen> createState() =>
      _ManageServerInvitesScreenState();
}

class _ManageServerInvitesScreenState extends State<ManageServerInvitesScreen> {
  int? _revokingId;

  @override
  void initState() {
    super.initState();
    context.read<InvitesBloc>().add(LoadServerInvites(widget.server.id!));
  }

  Future<void> _revoke(InviteData invite) async {
    final id = invite.id;
    if (id == null || _revokingId != null) return;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Отозвать приглашение?',
      description: 'Ссылка с кодом ${invite.code ?? '—'} перестанет работать.',
      confirmText: 'Отозвать',
      isDestructive: true,
      icon: CupertinoIcons.xmark_circle,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _revokingId = id);
    final bloc = context.read<InvitesBloc>();
    bloc.add(RevokeInvite(id));
    final result = await bloc.stream.firstWhere(
      (state) =>
          (state.lastCompleted == InviteOperation.revoke &&
              state.revokedId == id) ||
          state.failureFor(InviteOperation.revoke) != null,
    );
    if (!mounted) return;
    setState(() => _revokingId = null);
    final failure = result.failureFor(InviteOperation.revoke);
    if (failure != null) {
      CustomToast.open(context: context, message: failure.message);
    }
  }

  Widget _buildList(InvitesState state) {
    if (state.serverId != widget.server.id ||
        (state.isPending(InviteOperation.load) && state.invites.isEmpty)) {
      return const Center(child: CupertinoActivityIndicator());
    }
    final failure = state.failureFor(InviteOperation.load);
    if (failure != null && state.invites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                failure.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.greyple),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () => context.read<InvitesBloc>().add(
                  LoadServerInvites(widget.server.id!),
                ),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.invites.isEmpty) {
      return Center(
        child: Text(
          'Приглашений пока нет',
          style: TextStyle(color: AppColors.greyple),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: state.invites.length,
      itemBuilder: (context, index) {
        final invite = state.invites[index];
        return ServerInviteItem(
          key: ValueKey('invite_${invite.id ?? invite.code}'),
          invite: invite,
          isRevoking: _revokingId == invite.id,
          onCopy: () {
            final url = invite.inviteUrl;
            if (url != null) AppClipboard.copyText(context, url);
          },
          onRevoke: () => _revoke(invite),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => RoleScreenShell(
    title: 'Приглашения',
    subtitle: widget.server.name ?? 'Сервер',
    child: BlocBuilder<InvitesBloc, InvitesState>(
      builder: (context, state) => _buildList(state),
    ),
  );
}
