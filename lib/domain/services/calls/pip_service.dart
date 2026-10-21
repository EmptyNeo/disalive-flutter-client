import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  PipService._();

  static const MethodChannel _channel = MethodChannel('com.disalive/pip');
  static final ValueNotifier<bool> isInPipMode = ValueNotifier(false);
  static bool _initialized = false;

  static void initialize() {
    if (_initialized || !Platform.isAndroid) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPiPModeChanged') {
        isInPipMode.value = call.arguments == true;
      }
    });
  }

  static Future<bool> get isSupported async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isPipSupported') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> get isAllowed async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isPipAllowed') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> openSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openPipSettings') ?? false;
    } on PlatformException catch (error) {
      debugPrint('Opening PiP settings failed: $error');
      return false;
    }
  }

  static Future<void> setCallActive(bool active) async {
    if (!Platform.isAndroid) return;
    initialize();
    try {
      await _channel.invokeMethod<void>('setCallActive', active);
    } on PlatformException catch (error) {
      debugPrint('PiP state update failed: $error');
    }
  }

  static Future<void> startCallService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('startCallService');
    } on PlatformException catch (error) {
      debugPrint('Call foreground service failed: $error');
    }
  }

  static Future<void> stopCallService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stopCallService');
    } on PlatformException catch (error) {
      debugPrint('Stopping call foreground service failed: $error');
    }
  }
}
