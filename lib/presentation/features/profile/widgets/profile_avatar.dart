import 'dart:io';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/user_status.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class ProfileAvatar extends StatelessWidget {
  final String? url;
  final File? file;
  final UserStatus? status;
  final bool isBookmark;
  final double wh;
  final double size;
  final Color? colorOutline;

  const ProfileAvatar({
    super.key,
    this.url,
    this.file,
    this.status,
    this.isBookmark = false,
    this.wh = 80,
    this.size = 42,
    required this.colorOutline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorOutline,
        shape: BoxShape.circle,
      ),
      child: BuildAvatar(
        wh: wh,
        size: size,
        url: url,
        file: file,
        isBookmark: isBookmark,
        status: status,
        statusSize: size * 0.4,
        // Пропорциональный размер статуса
        statusPosition: 2,
      ),
    );
  }
}
