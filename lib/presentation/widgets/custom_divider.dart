import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: AppColors.divider);
  }
}
