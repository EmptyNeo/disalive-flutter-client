import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/moderation_appeal.dart';
import 'package:disalive/presentation/features/appeals/bloc/appeal_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/actions/action_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppealsHistoryScreen extends StatelessWidget {
  const AppealsHistoryScreen({super.key});

  static Future<void> open(BuildContext context) =>
      SwipeToDismissRoute.push<void>(
        context,
        (_) => BlocProvider(
          create: (_) => sl<AppealBloc>()..add(LoadAppeals()),
          child: const AppealsHistoryScreen(),
        ),
      );

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.transparent,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.mainBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                const ActionHeader(title: 'Мои апелляции', subtitle: null),
                Expanded(
                  child: BlocBuilder<AppealBloc, AppealState>(
                    builder: (context, state) => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (state.loading)
                          const Center(child: CupertinoActivityIndicator()),
                        if (!state.loading &&
                            state.appeals.isEmpty &&
                            state.failure == null)
                          Text(
                            'Апелляций пока нет',
                            style: TextStyle(color: AppColors.greyple),
                          ),
                        if (state.failure != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              state.failure!.message,
                              style: TextStyle(color: AppColors.errorRed),
                            ),
                          ),
                        for (final appeal in state.appeals) _AppealCard(appeal),
                      ],
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
}

class _AppealCard extends StatelessWidget {
  const _AppealCard(this.appeal);

  final ModerationAppeal appeal;

  @override
  Widget build(BuildContext context) {
    final status = switch (appeal.status) {
      'pending' => 'На рассмотрении',
      'approved' => 'Одобрена',
      'rejected' => 'Отклонена',
      _ => appeal.status,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.actionGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appeal.type.displayName,
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: appeal.isPending
                      ? AppColors.greyple
                      : AppColors.blurple,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (appeal.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              appeal.createdAt!,
              style: TextStyle(color: AppColors.greyple, fontSize: 12),
            ),
          ],
          if (appeal.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(appeal.reason, style: TextStyle(color: AppColors.white)),
          ],
          if (appeal.reviewerNote?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              'Ответ модератора: ${appeal.reviewerNote}',
              style: TextStyle(color: AppColors.greyple),
            ),
          ],
        ],
      ),
    );
  }
}
