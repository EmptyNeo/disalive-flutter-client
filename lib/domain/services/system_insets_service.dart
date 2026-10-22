import 'dart:io';

import 'package:flutter/services.dart';

class SystemInsetsService {
  static const _channel = MethodChannel('com.disalive/system_insets');

  static Future<double?> navigationBarBottom() async {
    if (!Platform.isAndroid) return null;
    try {
      final inset = await _channel.invokeMethod<double>('navigationBarBottom');
      return inset != null && inset.isFinite && inset >= 0 ? inset : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
