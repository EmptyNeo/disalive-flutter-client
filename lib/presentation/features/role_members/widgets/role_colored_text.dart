import 'package:disalive/domain/models/role_member.dart';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Renders role colors stored as HEX values, with a gradient when configured.
class RoleColoredText extends StatelessWidget {
  const RoleColoredText({
    super.key,
    required this.text,
    required this.role,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final RoleMember? role;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  Color? _color(String? hex) {
    if (hex == null) return null;
    final value = hex.substring(1);
    final normalized = value.length == 3
        ? value.split('').map((digit) => '$digit$digit').join()
        : value;
    final parsed = int.tryParse('FF$normalized', radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final start = _color(role?.gradientStart);
    final end = _color(role?.gradientEnd);
    final solid = _color(role?.color);
    final baseStyle = style ?? const TextStyle();
    final textWidget = Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      style: baseStyle.copyWith(
        color: start != null && end != null
            ? const Color(0xFFFFFFFF)
            : (solid ?? baseStyle.color),
      ),
    );

    if (start != null && end != null) {
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          final radians = role!.gradientAngle * math.pi / 180;
          // Mirrors CSS linear-gradient(angle): 90° runs left to right.
          final dx = math.sin(radians);
          final dy = -math.cos(radians);
          return LinearGradient(
            begin: Alignment(-dx, -dy),
            end: Alignment(dx, dy),
            colors: [start, end],
          ).createShader(bounds);
        },
        child: textWidget,
      );
    }
    return textWidget;
  }
}
