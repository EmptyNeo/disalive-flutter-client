// presentation/features/profile/widgets/profile_back_button.dart
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';

class ProfileBackButton extends StatelessWidget {
  const ProfileBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: GlassIconButton(
        icon: CupertinoIcons.back,
        onTap: () => Navigator.of(context).maybePop(),
        size: 36,
      ),
    );
  }
}
