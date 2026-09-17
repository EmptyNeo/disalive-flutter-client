// presentation/widgets/custom_back_button.dart
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';

class CustomBackButton extends StatelessWidget {
  final double positioned;
  const CustomBackButton({super.key, this.positioned = 8});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: positioned,
      left: positioned,
      child: GlassIconButton(
        icon: CupertinoIcons.back,
        onTap: () => Navigator.of(context).maybePop(),
        size: 36,
      ),
    );
  }
}
