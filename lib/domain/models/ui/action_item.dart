import 'package:flutter/cupertino.dart';

class ActionItem {
  final IconData icon;
  final Widget? leading;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;
  final bool isDestructive;

  const ActionItem({
    required this.icon,
    this.leading,
    required this.label,
    this.subtitle,
    this.onTap,
    this.color,
    this.isDestructive = false,
  });
}
