import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/presentation/features/server/widgets/unread_badge.dart';
import 'package:flutter/cupertino.dart';

class ServerItem extends StatelessWidget {
  final IconData icon;
  final Widget? actionIcon;
  final String? name;
  final String? pathAvatar;
  final bool isActive;
  final bool isSpecial;
  final bool isAction;
  final int unreadCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ServerItem({
    super.key,
    required this.icon,
    this.actionIcon,
    required this.isActive,
    required this.unreadCount,
    this.name,
    this.pathAvatar,
    this.isSpecial = false,
    this.isAction = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return Semantics(
      label: name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: isActive ? 32 : 0,
              decoration: BoxDecoration(
                color: AppColors.blurple,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.blurple : AppColors.actionGrey,
                    borderRadius: BorderRadius.circular(isActive ? 16 : 24),
                  ),
                  child: _buildContent(),
                ),
                if (hasUnread)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: UnreadBadge(count: unreadCount),
                  ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final url = _avatarUrl();
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    if (actionIcon != null) return actionIcon!;
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return Text(
        trimmedName.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: AppColors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Icon(
      icon,
      color: isAction ? AppColors.onBlurple : AppColors.white,
      size: 24,
    );
  }

  String? _avatarUrl() {
    final path = pathAvatar;
    if (path == null || path.isEmpty) return null;

    final transformed = Domain.transformUrl(path);
    final uri = Uri.tryParse(transformed);
    if (uri == null) return null;
    if (uri.hasScheme) return transformed;
    return Uri.parse(Domain.imageDomain).resolve(transformed).toString();
  }
}
