import 'package:disalive/domain/enums/user_status.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/status_dot.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserStatusSheet {
  static const _selectableStatuses = [
    UserStatus.online,
    UserStatus.idle,
    UserStatus.dnd,
    UserStatus.invisible,
  ];

  static Future<void> show(BuildContext context, UserModel user) {
    final profileBloc = context.read<ProfileBloc>();
    return ActionBottomSheet.show(
      context,
      title: 'Изменить статус',
      actions: [
        for (final status in _selectableStatuses)
          ActionItem(
            icon: CupertinoIcons.circle_fill,
            leading: StatusDot(status: status, size: 18),
            label: status == UserStatus.invisible
                ? 'Невидимый'
                : status.displayStatus,
            subtitle: status == UserStatus.dnd
                ? 'Вы не будете получать уведомление'
                : null,
            onTap: () {
              if (user.status == status) return;
              profileBloc.add(
                UpdateProfile(
                  UserModel(status: status),
                  loadingField: 'status',
                ),
              );
            },
          ),
      ],
    );
  }
}
