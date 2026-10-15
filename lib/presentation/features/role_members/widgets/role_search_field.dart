import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class RoleSearchField extends StatelessWidget {
  const RoleSearchField({
    super.key,
    required this.onChanged,
    this.placeholder = 'Поиск',
  });

  final ValueChanged<String> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: CupertinoSearchTextField(
      onChanged: onChanged,
      placeholder: placeholder,
      style: TextStyle(color: AppColors.white),
      placeholderStyle: TextStyle(color: AppColors.greyple),
      backgroundColor: AppColors.actionGrey,
      borderRadius: BorderRadius.circular(13),
    ),
  );
}
