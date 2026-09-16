import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ProfileBanner extends StatelessWidget {
  final Color? backgroundColor;
  final String? backgroundImageUrl;
  final double height;

  const ProfileBanner({
    super.key,
    required this.backgroundColor,
    this.backgroundImageUrl,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImageUrl != null
            ? DecorationImage(
                image: NetworkImage(backgroundImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
    );
    // Примечание: градиент будем добавлять на этапе сборки финального экрана,
    // как ты и просил ("градиент не должен заходить на баннер").
  }
}
