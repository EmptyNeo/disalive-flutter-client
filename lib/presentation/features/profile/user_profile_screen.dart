import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/complaint_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/request_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/friend_request.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/presentation/features/complaints/complaint_screen.dart';
import 'package:disalive/presentation/features/chat_server/bloc/chat_server_bloc.dart';
import 'package:disalive/presentation/features/gifs/bloc/gif_bloc.dart';
import 'package:disalive/presentation/features/home/home_screen.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/login.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/profile/bloc/featured_server_bloc.dart';
import 'package:disalive/presentation/features/profile/widgets/direct_profile_content.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_comments_section.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_qr_sheet.dart';
import 'package:disalive/presentation/features/reactions/bloc/preferred_reactions_bloc.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/members/moderation/entity_access_guard.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/ui/pluralize.dart';
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
  late final FeaturedServerBloc _featuredServerBloc;
  StreamSubscription<String>? _requestErrors;
  String? _pendingAction;
  bool _hasRequestOverride = false;
  FriendRequest? _requestOverride;
  bool _acceptedFriend = false;

  @override
  void initState() {
    super.initState();
    _featuredServerBloc = FeaturedServerBloc(
      sl<ServerRepository>(),
      sl<MembersRepository>(),
    );
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
    _featuredServerBloc.close();
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

  void _openFeaturedServer(Server server) {
    final id = server.id;
    if (id == null) return;
    final repository = sl<ServerRepository>();
    if (repository.getByIdCached(id) == null) {
      repository.updateCache([...repository.getCached(), server]);
    }
    final bloc = context.read<ServersBloc>();
    bloc.add(SelectServer(id));
    bloc.add(const GetServers());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _joinFeaturedServer(Server server) async {
    final id = server.id;
    if (id == null || _featuredServerBloc.state.joining) return;
    final access = await checkEntityAccess(
      context,
      EntityKey(entityId: id, entityType: EntityType.server),
    );
    if (access == null || !mounted) return;
    _featuredServerBloc.add(JoinFeaturedServer(id));
  }

  Widget? _profileActions(UserModel user, RequestsState requestsState) {
    final regular = _actions(user, requestsState);
    final server = user.featuredServer;
    if (server == null) return regular;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (regular != null) ...[regular, const SizedBox(height: 16)],
        BlocBuilder<FeaturedServerBloc, FeaturedServerState>(
          bloc: _featuredServerBloc,
          builder: (context, state) {
            final joined = state.joinedServer?.id == server.id;
            final member =
                joined ||
                server.memberId != null ||
                sl<ServerRepository>().getByIdCached(server.id ?? -1) != null;
            final image = server.pathAvatar;
            final imageUrl = image == null || image.isEmpty
                ? null
                : Domain.resolveImageUrl(image);
            return Container(
              key: const ValueKey('profile_featured_server'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.actionGrey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'СЕРВЕР ПОЛЬЗОВАТЕЛЯ',
                    style: AppText.lowTextStyle.copyWith(
                      color: AppColors.greyple,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: imageUrl == null || imageUrl.isEmpty
                              ? _featuredServerFallback(server)
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) =>
                                      _featuredServerFallback(server),
                                  errorWidget: (_, _, _) =>
                                      _featuredServerFallback(server),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.name ?? 'Сервер',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.mediumTextStyle.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (server.memberCount != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                Pluralize.members(server.memberCount!),
                                style: AppText.lowTextStyle.copyWith(
                                  color: AppColors.greyple,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      key: const ValueKey('profile_featured_server_action'),
                      color: AppColors.blurple,
                      borderRadius: BorderRadius.circular(10),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      onPressed: state.joining
                          ? null
                          : member
                          ? () => _openFeaturedServer(
                              state.joinedServer ?? server,
                            )
                          : () => _joinFeaturedServer(server),
                      child: state.joining
                          ? CupertinoActivityIndicator(color: AppColors.white)
                          : Text(
                              member ? 'Перейти на сервер' : 'Присоединиться',
                              style: AppText.mediumTextStyle.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _featuredServerFallback(Server server) => ColoredBox(
    color: AppColors.blurple,
    child: Center(
      child: Text(
        (server.name?.trim().isNotEmpty == true ? server.name!.trim()[0] : 'С')
            .toUpperCase(),
        style: AppText.mediumTextStyle.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
    ),
  );

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
    if (isSelf || user.id == null) return null;

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
        if (showFriendActions || showChatAction) const SizedBox(height: 8),
        _actionButton(
          'Пожаловаться',
          CupertinoIcons.flag,
          () => ComplaintScreen.open(
            context,
            type: ComplaintType.user,
            targetId: user.id!,
            targetName: user.getDisplayName,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeaturedServerBloc, FeaturedServerState>(
      bloc: _featuredServerBloc,
      listenWhen: (previous, current) =>
          previous.joinedServer != current.joinedServer ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.error != null) {
          CustomToast.open(context: context, message: state.error!);
        } else if (state.joinedServer != null) {
          _openFeaturedServer(state.joinedServer!);
        }
      },
      child: BlocListener<RequestsBloc, RequestsState>(
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
                                    actions: _profileActions(
                                      state.user,
                                      requestsState,
                                    ),
                                    footer: state.user.id == null
                                        ? null
                                        : ProfileCommentsSection(
                                            key: ValueKey(state.user.id),
                                            profileUserId: state.user.id!,
                                            canComment:
                                                state.user.id ==
                                                    sl<UserRepository>()
                                                        .getCurrentUser()
                                                        ?.id ||
                                                (state.user.allowComments !=
                                                        false &&
                                                    (state.user.allowOnlyFriendsComments !=
                                                            true ||
                                                        state.user.isFriend)),
                                          ),
                                  ),
                            ),

                          const CustomBackButton(),
                          if (state is ProfileLoaded)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () =>
                                    ProfileQrSheet.show(context, state.user),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.mainBackground.withValues(
                                      alpha: 0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.qrcode,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
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
      ),
    );
  }
}
