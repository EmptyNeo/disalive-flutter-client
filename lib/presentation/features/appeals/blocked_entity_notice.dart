import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/appeal_target_type.dart';
import 'package:disalive/domain/models/moderation_appeal.dart';
import 'package:disalive/presentation/features/appeals/appeal_screen.dart';
import 'package:disalive/presentation/features/appeals/appeals_history_screen.dart';
import 'package:disalive/presentation/features/appeals/bloc/appeal_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlockedEntityNotice extends StatelessWidget {
  const BlockedEntityNotice({
    super.key,
    required this.type,
    required this.id,
    required this.name,
    this.message,
    this.onClose,
  });

  final AppealTargetType type;
  final int? id;
  final String name;
  final String? message;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context, {
    required AppealTargetType type,
    required int? id,
    required String name,
  }) => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть уведомление',
    barrierColor: CupertinoColors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    pageBuilder: (dialogContext, _, _) => BlocProvider(
      create: (_) => sl<AppealBloc>()..add(LoadAppeals()),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlockedEntityNotice(
                type: type,
                id: id,
                name: name,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => BlocBuilder<AppealBloc, AppealState>(
    builder: (context, state) {
      AppealTarget? target;
      for (final item in state.targets) {
        if (item.type == type && (id == null || item.id == id)) {
          target = item;
          break;
        }
      }
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.mainBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_shield,
                  size: 26,
                  color: AppColors.errorRed,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$name заблокирован${type == AppealTargetType.server ? '' : 'а'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message ?? 'Доступ ограничен модерацией.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyple, fontSize: 13),
            ),
            if (target != null && state.isPending(target)) ...[
              const SizedBox(height: 20),
              Text(
                'Апелляция ожидает рассмотрения',
                style: TextStyle(color: AppColors.greyple),
              ),
            ],
            if (target != null && !state.isPending(target)) ...[
              const SizedBox(height: 20),
              CupertinoButton(
                color: AppColors.blurple,
                borderRadius: BorderRadius.circular(16),
                onPressed: () async {
                  await AppealScreen.open(context, target!);
                  if (context.mounted) {
                    context.read<AppealBloc>().add(LoadAppeals());
                  }
                },
                child: Text(
                  'Подать апелляцию',
                  style: TextStyle(color: AppColors.onBlurple),
                ),
              ),
            ],
            const SizedBox(height: 8),
            CupertinoButton(
              onPressed: () => AppealsHistoryScreen.open(context),
              child: Text(
                'Мои апелляции',
                style: TextStyle(color: AppColors.blurple),
              ),
            ),
            if (state.failure != null) ...[
              const SizedBox(height: 8),
              Text(
                state.failure!.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.errorRed, fontSize: 12),
              ),
            ],
            if (onClose != null) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: onClose,
                child: Text(
                  'Закрыть',
                  style: TextStyle(color: AppColors.greyple),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
