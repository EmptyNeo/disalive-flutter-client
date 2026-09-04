// lib/presentation/features/requests/widgets/requests_header.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';

/// Шапка экрана заявок — обычная строка в потоке (не floating), поэтому
/// без блюра: под ней ничего не скроллится.
class RequestsHeader extends StatelessWidget {
  const RequestsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Делаем симметричные отступы, например, по 12
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // Убираем BoxDecoration с BorderSide полностью
      child: Row(
        children: [
          GlassIconButton(
            icon: CupertinoIcons.back,
            size: 34,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Text(
            'Заявки в друзья',
            style: AppText.highTextStyle.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
