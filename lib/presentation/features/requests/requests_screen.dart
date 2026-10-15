// lib/presentation/features/requests/requests_screen.dart
import 'dart:async';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/friend_request.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/features/requests/widgets/request_item.dart';
import 'package:disalive/presentation/features/requests/widgets/requests_header.dart';
import 'package:disalive/presentation/features/requests/widgets/send_request_bar.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  static Future<void> open(BuildContext context) {
    // 1. Забираем уже существующий инстанс из HomeScreen
    final requestsBloc = context.read<RequestsBloc>();

    return SwipeToDismissRoute.push(
      context,
      (context) => BlocProvider.value(
        // 2. Передаем его вниз по дереву нового экрана
        value: requestsBloc,
        child: const RequestsScreen(),
      ),
    );
  }

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late final TextEditingController _usernameController;
  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  List<FriendRequest>? _cachedRequests;

  late StreamSubscription<String> _errorSubscription;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController();
    _usernameController.addListener(_onTextChanged);

    _errorSubscription = context.read<RequestsBloc>().errorStream.listen((
      errorMessage,
    ) {
      if (mounted) {
        CustomToast.open(context: context, message: errorMessage);
      }
    });
  }

  void _onTextChanged() {
    final hasText = _usernameController.text.trim().isNotEmpty;
    if (_hasText.value != hasText) {
      _hasText.value = hasText;
    }
  }

  @override
  void dispose() {
    _errorSubscription.cancel();
    _usernameController.removeListener(_onTextChanged);
    _usernameController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  void _onSendRequest() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    context.read<RequestsBloc>().add(SendRequest(username));
    _usernameController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _refresh() async {
    context.read<RequestsBloc>().add(GetRequests(true));
    await context.read<RequestsBloc>().stream.firstWhere(
      (s) => s is RequestsLoaded || s is RequestsFailure,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.mainBackground,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _refresh),

                  const SliverToBoxAdapter(child: RequestsHeader()),
                  SliverToBoxAdapter(
                    child: SendRequestBar(
                      controller: _usernameController,
                      hasText: _hasText,
                      onSend: _onSendRequest,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  BlocBuilder<RequestsBloc, RequestsState>(
                    builder: (context, state) {
                      if (state is RequestsLoaded) {
                        _cachedRequests = state.requests;
                      }

                      // Если данные загружаются, но у нас уже есть старый список — показываем его
                      if (state is RequestsLoading && _cachedRequests != null) {
                        if (_cachedRequests!.isEmpty) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyView(),
                          );
                        }
                        return _RequestsSliverList(requests: _cachedRequests!);
                      }

                      // Если данных вообще нет (первый запуск) — крутилка в центре
                      if (state is RequestsInitial ||
                          state is RequestsLoading) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CupertinoActivityIndicator()),
                        );
                      }

                      if (state is RequestsFailure) {
                        // Если произошла ошибка при обновлении, но есть кэш — лучше показать кэш или ошибку.
                        // Здесь при ошибке показываем экран ошибки, но если нужно, можно тоже fallback на кэш.
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: ErrorStateView(
                            failure: state.error,
                            onRetry: () => context.read<RequestsBloc>().add(
                              GetRequests(true),
                            ),
                          ),
                        );
                      }

                      final requests = (state as RequestsLoaded).requests;
                      if (requests.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyView(),
                        );
                      }

                      return _RequestsSliverList(requests: requests);
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestsSliverList extends StatelessWidget {
  const _RequestsSliverList({required this.requests});

  final List<FriendRequest> requests;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final request = requests[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: RequestItem(
            request: request,
            onAccept: request.isIncoming
                ? () => acceptRequest(context, request)
                : null,
            onReject: () => rejectRequest(context, request),
          ),
        );
      }, childCount: requests.length),
    );
  }

  void acceptRequest(BuildContext context, FriendRequest request) async {
    final bloc = context.read<RequestsBloc>();
    final username = request.user?.username ?? '';
    final displayName = request.user?.displayName ?? 'Пользователь';
    final confirmed = await showConfirmationDialog(
      context,
      title: "Принять запрос",
      description: "Вы уверены, что хотите принять запрос от $displayName",
    );

    if (confirmed == true) {
      bloc.add(AcceptRequest(username));
    }
  }

  void rejectRequest(BuildContext context, FriendRequest request) async {
    final bloc = context.read<RequestsBloc>();
    final username = request.user?.username ?? '';
    final displayName = request.user?.displayName ?? 'Пользователь';
    final confirmed = await showConfirmationDialog(
      context,
      title: "Отклонить запрос",
      description: "Вы уверены, что хотите отклонить запрос от $displayName",
    );

    if (confirmed == true) {
      bloc.add(CancelRequest(username));
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.person_2, size: 40, color: AppColors.greyple),
            const SizedBox(height: 12),
            Text(
              'Заявок пока нет.\nОтправьте заявку по имени пользователя',
              textAlign: TextAlign.center,
              style: AppText.mediumTextStyle.copyWith(color: AppColors.greyple),
            ),
          ],
        ),
      ),
    );
  }
}
