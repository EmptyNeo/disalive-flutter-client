import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

enum UserStatus {
  online('online'),
  idle('idle'),
  dnd('dnd'),
  offline('offline'),
  invisible('invisible');

  final String value;

  const UserStatus(this.value);

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserStatus.offline,
    );
  }

  String get displayStatus {
    switch (this) {
      case UserStatus.online:
        return 'В сети';
      case UserStatus.idle:
        return 'Неактивен';
      case UserStatus.dnd:
        return 'Не беспокоить';
      case UserStatus.invisible:
      case UserStatus.offline:
        return 'Не в сети';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.online:
        return AppColors.green;
      case UserStatus.idle:
        return AppColors.yellow;
      case UserStatus.dnd:
        return AppColors.errorRed;
      case UserStatus.invisible:
      case UserStatus.offline:
        return AppColors.greyple;
    }
  }
}
