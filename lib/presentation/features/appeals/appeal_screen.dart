import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/moderation_appeal.dart';
import 'package:disalive/presentation/features/appeals/bloc/appeal_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/actions/action_button.dart';
import 'package:disalive/presentation/widgets/actions/action_header.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppealScreen extends StatefulWidget {
  const AppealScreen({super.key, required this.target});

  final AppealTarget target;

  static Future<void> open(BuildContext context, AppealTarget target) =>
      SwipeToDismissRoute.push<void>(
        context,
        (_) => BlocProvider(
          create: (_) => sl<AppealBloc>()..add(LoadAppeals()),
          child: AppealScreen(target: target),
        ),
      );

  @override
  State<AppealScreen> createState() => _AppealScreenState();
}

class _AppealScreenState extends State<AppealScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppealBloc, AppealState>(
    listenWhen: (previous, current) => !previous.submitted && current.submitted,
    listener: (context, state) {
      CustomToast.open(
        context: context,
        message: 'Апелляция отправлена',
        color: AppColors.successGreen,
        icon: CupertinoIcons.check_mark_circled_solid,
      );
      Navigator.of(context).pop();
    },
    builder: (context, state) {
      final pending = state.isPending(widget.target);
      final allowed = state.canAppeal(widget.target);
      final length = _controller.text.trim().length;
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
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    ActionHeader(
                      title: 'Подать апелляцию',
                      subtitle: widget.target.name,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          Text(
                            'Объясните, почему блокировку следует пересмотреть.',
                            style: TextStyle(
                              color: AppColors.greyple,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            key: const ValueKey('appeal_reason_field'),
                            controller: _controller,
                            onChanged: (_) => setState(() {}),
                            maxLength: 4000,
                            minLines: 5,
                            maxLines: 10,
                            placeholder: 'Причина апелляции',
                            textCapitalization: TextCapitalization.sentences,
                            padding: const EdgeInsets.all(14),
                            style: TextStyle(color: AppColors.white),
                            decoration: BoxDecoration(
                              color: AppColors.actionGrey,
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$length / 4000 (минимум 10)',
                            style: TextStyle(
                              color: AppColors.greyple,
                              fontSize: 12,
                            ),
                          ),
                          if (state.loading)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: CupertinoActivityIndicator(),
                            ),
                          if (pending ||
                              (!allowed &&
                                  state.targetsLoaded &&
                                  !state.loading))
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                pending
                                    ? 'Апелляция уже ожидает рассмотрения.'
                                    : 'Для этого объекта апелляция недоступна.',
                                style: TextStyle(color: AppColors.greyple),
                              ),
                            ),
                          if (state.failure != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                state.failure!.message,
                                style: TextStyle(color: AppColors.errorRed),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ActionButton(
                      title: 'Отправить апелляцию',
                      onTap: () => context.read<AppealBloc>().add(
                        SubmitAppeal(widget.target, _controller.text),
                      ),
                      canPress:
                          allowed &&
                          !pending &&
                          !state.loading &&
                          !state.submitting &&
                          length >= 10 &&
                          length <= 4000,
                      isLoading: state.submitting,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
