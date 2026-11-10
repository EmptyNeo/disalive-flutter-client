import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/complaint_severity.dart';
import 'package:disalive/domain/enums/complaint_type.dart';
import 'package:disalive/domain/models/complaint_submission.dart';
import 'package:disalive/presentation/features/complaints/bloc/complaint_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/actions/action_button.dart';
import 'package:disalive/presentation/widgets/actions/action_header.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({
    super.key,
    required this.type,
    required this.targetId,
    this.targetName,
    this.targetChannelId,
  });

  final ComplaintType type;
  final int targetId;
  final String? targetName;
  final int? targetChannelId;

  static Future<int?> open(
    BuildContext context, {
    required ComplaintType type,
    required int targetId,
    String? targetName,
    int? targetChannelId,
  }) => SwipeToDismissRoute.push<int>(
    context,
    (_) => BlocProvider(
      create: (_) => sl<ComplaintBloc>(),
      child: ComplaintScreen(
        type: type,
        targetId: targetId,
        targetName: targetName,
        targetChannelId: targetChannelId,
      ),
    ),
  );

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  static const _reasons = <({String title, String description})>[
    (title: 'Спам', description: 'Реклама, повторяющиеся сообщения или ссылки'),
    (
      title: 'Домогательство',
      description: 'Оскорбления, угрозы или преследование',
    ),
    (
      title: 'Неуместный контент',
      description: 'Неприемлемый или оскорбительный контент',
    ),
    (
      title: 'Вредоносный контент',
      description: 'Вирусы, фишинг или мошенничество',
    ),
    (title: 'Насилие', description: 'Пропаганда насилия или экстремизма'),
    (title: 'Другое', description: 'Причина не указана в списке'),
  ];

  final _detailsController = TextEditingController();
  String? _reason;
  ComplaintSeverity _severity = ComplaintSeverity.medium;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason;
    if (reason == null || widget.targetId < 1) return;
    FocusScope.of(context).unfocus();
    context.read<ComplaintBloc>().add(
      SubmitComplaint(
        ComplaintSubmission(
          type: widget.type,
          targetId: widget.targetId,
          reason: reason,
          details: _detailsController.text,
          severity: _severity,
          targetChannelId: widget.targetChannelId,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: TextStyle(
      color: AppColors.greyple,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _choice({
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.highlight : AppColors.actionGrey,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? AppColors.blurple
                : AppColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(color: AppColors.greyple, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: selected ? AppColors.blurple : AppColors.greyple,
              size: 21,
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ComplaintBloc, ComplaintState>(
    listenWhen: (previous, current) => previous.status != current.status,
    listener: (context, state) {
      if (state.status == ComplaintSubmitStatus.success) {
        CustomToast.open(
          context: context,
          message: 'Жалоба отправлена',
          color: AppColors.successGreen,
          icon: CupertinoIcons.check_mark_circled_solid,
        );
        Navigator.of(context).pop(state.complaintId);
      }
    },
    builder: (context, state) {
      final submitting = state.status == ComplaintSubmitStatus.submitting;
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Column(
                        children: [
                          ActionHeader(
                            title:
                                'Пожаловаться на ${widget.type.accusativeName}',
                            subtitle:
                                widget.targetName ??
                                'Расскажите, что произошло',
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              children: [
                                _sectionTitle('ПРИЧИНА ЖАЛОБЫ'),
                                const SizedBox(height: 10),
                                for (final reason in _reasons)
                                  _choice(
                                    title: reason.title,
                                    description: reason.description,
                                    selected: _reason == reason.title,
                                    onTap: () =>
                                        setState(() => _reason = reason.title),
                                  ),
                                const SizedBox(height: 16),
                                _sectionTitle('ДЕТАЛИ (НЕОБЯЗАТЕЛЬНО)'),
                                const SizedBox(height: 8),
                                CupertinoTextField(
                                  key: const ValueKey(
                                    'complaint_details_field',
                                  ),
                                  controller: _detailsController,
                                  maxLength: 5000,
                                  minLines: 3,
                                  maxLines: 6,
                                  placeholder:
                                      'Опишите подробнее, что произошло...',
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  padding: const EdgeInsets.all(14),
                                  style: TextStyle(color: AppColors.white),
                                  decoration: BoxDecoration(
                                    color: AppColors.actionGrey,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _sectionTitle('СЕРЬЁЗНОСТЬ'),
                                const SizedBox(height: 10),
                                for (final severity in ComplaintSeverity.values)
                                  _choice(
                                    title: severity.displayName,
                                    description: severity.description,
                                    selected: _severity == severity,
                                    onTap: () =>
                                        setState(() => _severity = severity),
                                  ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.actionGrey,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        CupertinoIcons.info_circle,
                                        color: AppColors.greyple,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Жалобу рассмотрят модераторы. Пожалуйста, не отправляйте ложные жалобы.',
                                          style: TextStyle(
                                            color: AppColors.greyple,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (state.failure != null) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    state.failure!.message,
                                    style: TextStyle(
                                      color: AppColors.errorRed,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 72),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ActionButton(
                        title: 'Отправить жалобу',
                        onTap: _submit,
                        canPress:
                            _reason != null &&
                            widget.targetId > 0 &&
                            !submitting,
                        isLoading: submitting,
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
  );
}
