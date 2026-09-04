import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/requests/requests_screen.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
import 'package:flutter/cupertino.dart';

class DmNormalHeader extends StatelessWidget {
  final VoidCallback onSearchTap;

  const DmNormalHeader({super.key, required this.onSearchTap});

  static const double _buttonRadius = 32;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
          child: Text(
            'Личные сообщения',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GlassButton(
                borderRadius: _buttonRadius,
                padding: const EdgeInsets.all(11),
                onTap: onSearchTap,
                child: Icon(
                  CupertinoIcons.search,
                  color: AppColors.white.withValues(alpha: 0.75),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  borderRadius: _buttonRadius,
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        CupertinoIcons.person_add_solid,
                        color: AppColors.white.withOpacity(0.75),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Добавить в друзья',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    RequestsScreen.open(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
