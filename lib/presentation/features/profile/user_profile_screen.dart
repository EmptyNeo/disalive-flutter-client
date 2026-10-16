import 'dart:async';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/request_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/friend_request.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/presentation/features/chat_server/bloc/chat_server_bloc.dart';
import 'package:disalive/presentation/features/gifs/bloc/gif_bloc.dart';
import 'package:disalive/presentation/features/home/home_screen.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/login.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/profile/widgets/direct_profile_content.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_qr_sheet.dart';
import 'package:disalive/presentation/features/reactions/bloc/preferred_reactions_bloc.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserProfileScreen extends StatelessWidget {
  final String username;
  final UserModel? initialUser;

  const UserProfileScreen({
    super.key,
    required this.username,
    this.initialUser,
  });

  static Future<void> open(
    BuildContext context, {
    required String username,
    UserModel? initialUser,
  }) {
    final scope = HomeScreen.scopeContext ?? context;
    final requestsBloc = scope.read<RequestsBloc>();
    final chatBloc = scope.read<ChatBloc>();
    final messageBloc = scope.read<MessageBloc>();
    final chatServerBloc = scope.read<ChatServerBloc>();
    final membersBloc = scope.read<MembersBloc>();
    final gifBloc = scope.read<GifBloc>();
    final stickersBloc = scope.read<StickersPackBloc>();
    final reactionsBloc = scope.read<PreferredReactionsBloc>();
    final invitesBloc = scope.read<InvitesBloc>();
    final mediaStatsBloc = scope.read<MediaStatsBloc>();
    final serversBloc = scope.read<ServersBloc>();
    return SwipeToDismissRoute.push(
      context,
      (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: requestsBloc),
          BlocProvider.value(value: chatBloc),
          BlocProvider.value(value: messageBloc),
          BlocProvider.value(value: chatServerBloc),
          BlocProvider.value(value: membersBloc),
          BlocProvider.value(value: gifBloc),
          BlocProvider.value(value: stickersBloc),
          BlocProvider.value(value: reactionsBloc),
          BlocProvider.value(value: invitesBloc),
          BlocProvider.value(value: mediaStatsBloc),
          BlocProvider.value(value: serversBloc),
        ],
        child: UserProfileScreen(username: username, initialUser: initialUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileBloc>()
        ..setupListeners()
        ..add(
          GetProfileByUsername(username: username, initialUser: initialUser),
        ),
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatefulWidget {
  const _UserProfileView();

  @override
  State<_UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<_UserProfileView> {
  StreamSubscription<String>? _requestErrors;
  String? _pendingAction;
  bool _hasRequestOverride = false;
  FriendRequest? _requestOverride;
  bool _acceptedFriend = false;

  @override
  void initState() {
    super.initState();
    _requestErrors = context.read<RequestsBloc>().errorStream.listen((error) {
      if (!mounted) return;
      setState(() => _pendingAction = null);
      CustomToast.open(
        context: context,
        icon: CupertinoIcons.exclamationmark_circle,
        color: AppColors.errorRed,
        message: error,
      );
    });
  }

  @override
  void dispose() {
    _requestErrors?.cancel();
    super.dispose();
  }

  void _onRequestsChanged(RequestsState state) {
    if (state is! RequestsLoaded || _pendingAction == null) return;
    final action = _pendingAction!;
    setState(() {
      _pendingAction = null;
      _hasRequestOverride = true;
      _requestOverride = action == 'send'
          ? const FriendRequest(type: RequestType.outgoing)
          : null;
      if (action == 'accept') _acceptedFriend = true;
    });
  }

  void _dispatch(String action, String username) {
    if (_pendingAction != null) return;
    setState(() => _pendingAction = action);
    final bloc = context.read<RequestsBloc>();
    switch (action) {
      case 'send':
        bloc.add(SendRequest(username));
      case 'accept':
        bloc.add(AcceptRequest(username));
      case 'cancel':
        bloc.add(CancelRequest(username));
    }
  }

  void _openChat(UserModel user) {
    final chatId = user.personalChatId;
    if (chatId == null) return;
    final cached = sl<ChatRepository>().getCached();
    final chat =
        cached.where((item) => item.id == chatId).firstOrNull ??
        Chat(
          id: chatId,
          name: user.getDisplayName,
          type: ChatType.personal,
          isPersonal: true,
          user: user,
        );
    ChatScreen.open(context, chat, false);
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool primary = false,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: primary ? AppColors.blurple : AppColors.actionGrey,
      borderRadius: BorderRadius.circular(12),
      onPressed: _pendingAction == null ? onPressed : null,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget? _actions(UserModel user, RequestsState requestsState) {
    final username = user.username;
    final cachedRequest = requestsState is RequestsLoaded
        ? requestsState.requests
              .where(
                (request) =>
                    (user.id != null && request.user?.id == user.id) ||
                    (username != null && request.user?.username == username) ||
                    (request.id != null &&
                        request.id == user.friendRequest?.id),
              )
              .firstOrNull
        : null;
    final request = _hasRequestOverride
        ? _requestOverride
        : cachedRequest ?? user.friendRequest;
    final incomingRequest =
        request?.isIncoming == true ||
        (request?.type == null &&
            user.id != null &&
            request?.senderId == user.id);
    final currentUser = sl<UserRepository>().getCurrentUser();
    final isSelf =
        (user.id != null && user.id == currentUser?.id) ||
        (username != null && username == currentUser?.username);
    final showFriendActions =
        !isSelf &&
        username != null &&
        username.isNotEmpty &&
        !user.isFriend &&
        !_acceptedFriend &&
        (request != null || user.canSendMeRequest != false);
    final showChatAction = !isSelf && user.personalChatId != null;
    if (!showFriendActions && !showChatAction) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showFriendActions && incomingRequest) ...[
          _actionButton(
            'Принять',
            CupertinoIcons.checkmark,
            () => _dispatch('accept', username),
            primary: true,
          ),
          const SizedBox(height: 8),
          _actionButton(
            'Отклонить',
            CupertinoIcons.xmark,
            () => _dispatch('cancel', username),
          ),
        ] else if (showFriendActions && request != null)
          _actionButton(
            'Отменить заявку',
            CupertinoIcons.xmark,
            () => _dispatch('cancel', username),
          )
        else if (showFriendActions)
          _actionButton(
            'Добавить в друзья',
            CupertinoIcons.person_add,
            () => _dispatch('send', username),
            primary: true,
          ),
        if (showChatAction) ...[
          if (showFriendActions) const SizedBox(height: 8),
          _actionButton(
            'Открыть чат',
            CupertinoIcons.chat_bubble_2,
            () => _openChat(user),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RequestsBloc, RequestsState>(
      listener: (context, state) => _onRequestsChanged(state),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is AuthLogoutState) {
            LoginScreen.routeToMe(context);
          }
        },
        builder: (context, state) {
          return CupertinoPageScaffold(
            backgroundColor: CupertinoColors.transparent,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 6.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: AppColors.mainBackground,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (state is ProfileLoading)
                          const Center(child: CupertinoActivityIndicator())
                        else if (state is ProfileFailure)
                          Center(
                            child: Text(
                              'Не удалось загрузить профиль',
                              style: TextStyle(
                                color: AppColors.greyple,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else if (state is ProfileLoaded)
                          BlocBuilder<RequestsBloc, RequestsState>(
                            builder: (context, requestsState) =>
                                DirectProfileContent(
                                  user: state.user,
                                  isSoloChat: false,
                                  actions: _actions(state.user, requestsState),
                                ),
                          ),

                        const CustomBackButton(),
                        if (state is ProfileLoaded)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: CupertinoButton(
                              padding: const EdgeInsets.all(8),
                              color: AppColors.mainBackground.withValues(
                                alpha: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: () =>
                                  ProfileQrSheet.show(context, state.user),
                              child: const Icon(
                                CupertinoIcons.qrcode,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
