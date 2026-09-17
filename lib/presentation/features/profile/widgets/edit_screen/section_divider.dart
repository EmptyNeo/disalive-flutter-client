import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppWidgetStyles.dividerDecoration,
    );
  }
}
