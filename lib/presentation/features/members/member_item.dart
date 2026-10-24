import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/items/badge_item.dart';
import 'package:disalive/presentation/features/profile/user_profile_screen.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_emoji.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class MemberItem extends StatefulWidget {
  final Member member;
  final VoidCallback onLongPress;

  const MemberItem({
    super.key,
    required this.member,
    required this.onLongPress,
  });

  @override
  State<MemberItem> createState() => _MemberItemState();
}

class _MemberItemState extends State<MemberItem> {
  bool _isPressed = false;

  int _textFlex(String text, TextStyle style, BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.ceil().clamp(1, 10000);
  }

  void _handlePressStart() {
    setState(() => _isPressed = true);
  }

  void _handlePressEnd() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = widget.member.user;

    // Исправлено: SizedBox.shrink не принимает child.
    // Если данные не загрузились, показываем аккуратную заглушку.
    if (user == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          "Не удалось загрузить данные участника",
          style: TextStyle(color: AppColors.greyple, fontSize: 13),
        ),
      );
    }

    final roleName = widget.member.role?.name?.trim() ?? '';
    final roleEmoji = widget.member.role?.emoji?.trim() ?? '';
    final hasRole = roleName.isNotEmpty || roleEmoji.isNotEmpty;
    final badge = user.mainBadge;
    final nameStyle = TextStyle(
      color: AppColors.white,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    final roleStyle = TextStyle(
      color: AppColors.greyple,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    final nameFlex = _textFlex(user.getDisplayName, nameStyle, context);
    final roleFlex = hasRole
        ? _textFlex(roleName, roleStyle, context) +
              14 +
              (roleEmoji.isNotEmpty ? 16 + (roleName.isNotEmpty ? 4 : 0) : 0)
        : 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Реагируем на начало касания (и обычного тапа, и долгого зажатия)
      onTap: () {
        UserProfileScreen.open(
          context,
          username: widget.member.user?.username ?? '',
        );
      },
      onTapDown: (_) => _handlePressStart(),
      onLongPressDown: (_) => _handlePressStart(),

      // Реагируем на окончание или отмену касания (палец убрали или ушел за пределы)
      onTapUp: (_) => _handlePressEnd(),
      onTapCancel: _handlePressEnd,
      onLongPressUp: _handlePressEnd,
      onLongPressCancel: _handlePressEnd,

      onLongPress: widget.onLongPress,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // 🎯 Меняем фон при зажатии на полупрозрачный белый (стеклянный эффект)
          color: _isPressed
              ? AppColors.white.withValues(alpha: 0.08)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            BuildAvatar(
              url: user.urlAvatar,
              wh: 32,
              size: 22,
              status: widget.member.user?.status,
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: nameFlex,
              fit: FlexFit.loose,
              child: Text(
                user.getDisplayName,
                style: nameStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasRole) ...[
              const SizedBox(width: 5),
              Flexible(
                flex: roleFlex,
                fit: FlexFit.loose,
                child: Container(
                  key: const ValueKey('member_role'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.actionGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (roleName.isNotEmpty)
                        Flexible(
                          child: Text(
                            roleName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: roleStyle,
                          ),
                        ),
                      if (roleEmoji.isNotEmpty) ...[
                        if (roleName.isNotEmpty) const SizedBox(width: 4),
                        RoleEmoji(roleEmoji, size: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (badge != null) ...[
              const SizedBox(width: 5),
              BadgeItem(badge: badge, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
