import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/app_selection_sheet.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';

class MemberModerationScreen extends StatefulWidget {
  const MemberModerationScreen({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.entityName,
    required this.member,
    required this.action,
  });

  final int entityId;
  final EntityType entityType;
  final String entityName;
  final Member member;
  final String action;

  static Future<void> open(
    BuildContext context, {
    required int entityId,
    required EntityType entityType,
    required String entityName,
    required Member member,
    required String action,
  }) => SwipeToDismissRoute.push<void>(
    context,
    (_) => MemberModerationScreen(
      entityId: entityId,
      entityType: entityType,
      entityName: entityName,
      member: member,
      action: action,
    ),
  );

  @override
  State<MemberModerationScreen> createState() => _MemberModerationScreenState();
}

class _MemberModerationScreenState extends State<MemberModerationScreen> {
  final _reasonController = TextEditingController();
  int _durationHours = 0;
  bool _saving = false;

  bool get _isBan => widget.action == 'ban';

  String get _durationLabel => switch (_durationHours) {
    0 => 'Бессрочно',
    1 => '1 час',
    24 => '24 часа',
    168 => '7 дней',
    720 => '30 дней',
    _ => '$_durationHours ч.',
  };

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _chooseDuration() async {
    final selected = await AppSelectionSheet.show<int>(
      context,
      title: 'Срок оглушения',
      selectedValue: _durationHours,
      options: const [
        AppSelectionOption(value: 0, label: 'Бессрочно'),
        AppSelectionOption(value: 1, label: '1 час'),
        AppSelectionOption(value: 24, label: '24 часа'),
        AppSelectionOption(value: 168, label: '7 дней'),
        AppSelectionOption(value: 720, label: '30 дней'),
      ],
    );
    if (selected != null && mounted) {
      setState(() => _durationHours = selected);
    }
  }

  Future<void> _save() async {
    final userId = widget.member.fkUser;
    if (userId == null || _saving) return;
    setState(() => _saving = true);
    final expiresAt = _durationHours == 0
        ? null
        : DateTime.now()
              .toUtc()
              .add(Duration(hours: _durationHours))
              .toIso8601String();
    final result = await sl<MembersRepository>().moderate(
      entityKey: EntityKey(
        entityId: widget.entityId,
        entityType: widget.entityType,
      ),
      userId: userId,
      action: widget.action,
      expiresAt: expiresAt,
      reason: _reasonController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) => RoleScreenShell(
    title: _isBan ? 'Заблокировать участника' : 'Обезмолвить участника',
    subtitle: widget.entityName,
    actionTitle: _isBan ? 'Заблокировать' : 'Обезмолвить',
    onAction: _save,
    actionEnabled: !_saving && widget.member.fkUser != null,
    actionLoading: _saving,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          widget.member.user?.getDisplayName ?? 'Участник',
          style: AppText.highTextStyle.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 20),
        Text(
          _isBan ? 'Срок блокировки' : 'Срок оглушения',
          style: TextStyle(color: AppColors.greyple, fontSize: 13),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(13),
          onPressed: _chooseDuration,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _durationLabel,
                  style: TextStyle(color: AppColors.white),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: AppColors.greyple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isBan ? 'Причина блокировки' : 'Причина оглушения',
          style: TextStyle(color: AppColors.greyple, fontSize: 13),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _reasonController,
          maxLength: 500,
          minLines: 3,
          maxLines: 5,
          placeholder: 'Можно оставить пустым',
          padding: const EdgeInsets.all(14),
          style: TextStyle(color: AppColors.white),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ],
    ),
  );
}
