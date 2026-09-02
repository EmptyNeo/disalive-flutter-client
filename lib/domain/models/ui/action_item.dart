import 'package:flutter/cupertino.dart';

class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool isDestructive;

  const ActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.isDestructive = false,
  });
}
