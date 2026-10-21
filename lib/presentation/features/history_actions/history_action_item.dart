import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/user_profile_screen.dart';
import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:flutter/cupertino.dart';

class HistoryActionItem extends StatelessWidget {
  const HistoryActionItem({super.key, required this.action});

  final HistoryAction action;

  @override
  Widget build(BuildContext context) {
    final type = action.entityActionType;
    final isChat = action.entityType == EntityType.chat;
    final icon = switch (type) {
      EntityActionType.called => CupertinoIcons.phone_fill,
      EntityActionType.joined ||
      EntityActionType.added => CupertinoIcons.person_add_solid,
      _ => CupertinoIcons.person_crop_circle_badge_minus,
    };
    final color = type == EntityActionType.called
        ? AppColors.green
        : type == EntityActionType.joined || type == EntityActionType.added
        ? AppColors.blurple
        : AppColors.greyple;
    final localTime = action.startTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(action.startTimestamp! * 1000)
        : UtilDate.parseDateTime(action.startDate);
    final time = localTime == null
        ? (action.startTimeFormatted ?? '')
        : '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  _userSpan(context, action.initiatorUser, action.userId),
                  TextSpan(
                    text: switch (type) {
                      EntityActionType.called => ' начал звонок',
                      EntityActionType.joined =>
                        isChat
                            ? ' присоединился к группе'
                            : ' присоединился к серверу',
                      EntityActionType.cameout =>
                        isChat ? ' вышел из группы' : ' вышел с сервера',
                      EntityActionType.lefted => ' выгнал ',
                      EntityActionType.excluded => ' исключил ',
                      EntityActionType.added => ' добавил ',
                      null => ' выполнил действие',
                    },
                  ),
                  if (type == EntityActionType.lefted ||
                      type == EntityActionType.excluded ||
                      type == EntityActionType.added) ...[
                    _userSpan(
                      context,
                      action.interactionUser,
                      action.interactionUserId,
                    ),
                    TextSpan(
                      text: type == EntityActionType.added
                          ? (isChat ? ' в группу' : ' на сервер')
                          : (isChat ? ' из группы' : ' с сервера'),
                    ),
                  ],
                ],
              ),
              style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
            ),
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              time,
              style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
            ),
          ],
        ],
      ),
    );
  }

  InlineSpan _userSpan(BuildContext context, UserModel? user, int? id) {
    final username = user?.username;
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        onTap: username == null || username.isEmpty
            ? null
            : () => UserProfileScreen.open(context, username: username),
        child: Text(
          user?.displayName ??
              (id == null ? 'Пользователь' : 'Пользователь $id'),
          style: AppText.lowTextStyle.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontFamily: user?.fontUsername,
          ),
        ),
      ),
    );
  }
}
