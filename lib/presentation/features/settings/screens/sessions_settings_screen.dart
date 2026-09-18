// lib/presentation/features/settings/screens/sessions_settings_screen.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_session_type.dart';
import 'package:disalive/domain/models/session.dart';
import 'package:disalive/presentation/bloc/session/session_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SessionsSettingsScreen extends StatefulWidget {
  const SessionsSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    final sessionBloc = context.read<SessionBloc>();
    return SwipeToDismissRoute.push(
      context,
      (context) => BlocProvider.value(
        value: sessionBloc,
        child: const SessionsSettingsScreen(),
      ),
    );
  }

  @override
  State<SessionsSettingsScreen> createState() => _SessionsSettingsScreenState();
}

class _SessionsSettingsScreenState extends State<SessionsSettingsScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<SessionBloc>();
    bloc.setupListeners();
    bloc.add(LoadSessions());
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
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BlocBuilder<SessionBloc, SessionState>(
                builder: (context, state) {
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(context)),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      ..._buildBody(context, state),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconButton(
                icon: CupertinoIcons.back,
                onTap: () => Navigator.of(context).pop(),
                size: 36,
              ),
              const SizedBox(width: 12),
              Text('Устройства', style: AppText.highTextStyle),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Здесь перечислены все устройства, на которых выполнен вход '
              'в вашу учётную запись Disalive.',
              style: AppText.lowTextStyle.copyWith(
                color: AppColors.greyple,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, SessionState state) {
    if (state is SessionLoading || state is SessionInitial) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ];
    }

    if (state is SessionFailure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorStateView(
            failure: state.error,
            onRetry: () => context.read<SessionBloc>().add(LoadSessions()),
          ),
        ),
      ];
    }

    if (state is SessionLoaded) {
      final sessions = state.sessions;

      if (sessions.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Нет активных сессий',
                style: AppText.mediumTextStyle.copyWith(
                  color: AppColors.greyple,
                ),
              ),
            ),
          ),
        ];
      }

      final current = sessions
          .where((s) => s.isCurrentSession)
          .cast<SessionModel?>()
          .firstWhere((s) => s != null, orElse: () => null);
      final others = sessions.where((s) => !s.isCurrentSession).toList();

      return [
        if (current != null) ...[
          SliverToBoxAdapter(
            child: _buildCurrentSessionCard(context, current, others.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        if (others.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final session = others[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildSessionCard(context, session),
              );
            }, childCount: others.length),
          ),
      ];
    }

    // SessionLoggedOut или иное состояние — ничего не рисуем здесь,
    // навигация на экран логина должна произойти выше по дереву.
    return const [SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  Widget _buildCurrentSessionCard(
    BuildContext context,
    SessionModel session,
    int othersCount,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      // 🎯 ClipRRect гарантирует, что ни один дочерний элемент не вылезет за скругление
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🎯 ИСПРАВЛЕННАЯ СИНЯЯ ПОЛОСКА
              Container(
                width: 3,
                decoration: const BoxDecoration(
                  color: AppColors.blurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blurple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _deviceIcon(session),
                              color: AppColors.blurple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _title(session),
                                  style: AppText.mediumTextStyle.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _subtitle(session),
                                  style: AppText.lowTextStyle.copyWith(
                                    color: AppColors.greyple,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Текущий сеанс · Вошли: ${_formatDateTime(session.createdAt)}',
                        style: AppText.lowTextStyle.copyWith(
                          color: AppColors.greyple,
                          fontSize: 12,
                        ),
                      ),
                      if (othersCount > 0) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () =>
                                _confirmDeleteAllOthers(context, session.id),
                            child: Text(
                              'Завершить все остальные сеансы',
                              style: AppText.mediumTextStyle.copyWith(
                                color: AppColors.onBlurple,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, SessionModel session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // 🎯 Убрали хак с padding: 40 справа. Теперь всё контролируется через Stack.
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _deviceIcon(session),
                  color: AppColors.greyple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(session),
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle(session),
                      style: AppText.lowTextStyle.copyWith(
                        color: AppColors.greyple,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Вошли: ${_formatDateTime(session.createdAt)}',
                      style: AppText.lowTextStyle.copyWith(
                        color: AppColors.greyple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 🎯 ИСПРАВЛЕННАЯ КНОПКА ЗАКРЫТИЯ СЕССИИ
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _confirmDeleteSession(context, session),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  // Легкий красный фон делает кнопку заметной и указывает на деструктивное действие
                  color: AppColors.errorRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: AppColors.errorRed, // Красный цвет иконки
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    SessionModel session,
  ) async {
    final bloc = context.read<SessionBloc>();
    final result =
        await showConfirmationDialog(
          context,
          title: 'Завершить сеанс?',
          description:
              'Устройство «${_title(session)}» будет разлогинено из аккаунта.',
        ) ??
        false;

    if (result) {
      bloc.add(DeleteSession(id: session.id, type: ActionSessionType.target));
    }
  }

  Future<void> _confirmDeleteAllOthers(
    BuildContext context,
    int currentSessionId,
  ) async {
    final bloc = context.read<SessionBloc>();
    final result =
        await showConfirmationDialog(
          context,
          title: 'Завершить все остальные сеансы?',
          description:
              'Все устройства, кроме текущего, будут разлогинены из аккаунта.',
        ) ??
        false;

    if (result) {
      bloc.add(
        DeleteSession(id: currentSessionId, type: ActionSessionType.others),
      );
    }
  }

  IconData _deviceIcon(SessionModel session) {
    final platform = (session.platform ?? '').toLowerCase();
    final deviceType = (session.deviceType ?? '').toLowerCase();

    final looksMobile =
        platform.contains('mobile') ||
        deviceType.contains('mobile') ||
        deviceType.contains('android') ||
        deviceType.contains('ios');

    return looksMobile
        ? CupertinoIcons.device_phone_portrait
        : CupertinoIcons.desktopcomputer;
  }

  // Проверка "есть ли значение, которое стоит показывать" — в переданной
  // JS-логике isKnown() не показан, беру по обычному смыслу: не null, не
  // пустая строка после trim, и не служебное "unknown", которое иногда
  // отдают парсеры user-agent. Поправь, если у тебя isKnown проверяет
  // что-то ещё.
  bool _isKnown(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.toLowerCase() != 'unknown';
  }

  String _title(SessionModel session) {
    if (_isKnown(session.browserName)) {
      return _isKnown(session.browserVersion)
          ? '${session.browserName} ${session.browserVersion}'
          : session.browserName!;
    }
    if (_isKnown(session.platform)) return session.platform!;
    if (_isKnown(session.deviceType)) return session.deviceType!;
    return 'Неизвестное устройство';
  }

  /// Подзаголовок: ОС + версия, при необходимости тип устройства.
  /// Возвращает '', если показать нечего — тогда строку не рендерим вовсе
  /// (см. использование ниже).
  String _subtitle(SessionModel session) {
    final parts = <String>[];

    if (_isKnown(session.osName)) {
      parts.add(
        _isKnown(session.osVersion)
            ? '${session.osName} ${session.osVersion}'
            : session.osName!,
      );
    }

    if (_isKnown(session.deviceType) &&
        session.deviceType!.toLowerCase() != 'desktop') {
      parts.add(session.deviceType!);
    }

    return parts.join(' · ');
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;

    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}, '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}
