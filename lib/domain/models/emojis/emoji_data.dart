import 'dart:convert';
import 'package:flutter/services.dart';

class EmojiFrame {
  final double x;
  final double y;

  EmojiFrame({required this.x, required this.y});

  factory EmojiFrame.fromJson(Map<String, dynamic> json) {
    return EmojiFrame(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}