import 'dart:io';
import 'package:disalive/domain/repositories/permission_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  @override
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestPhotosPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      if (status.isGranted) return true;
      return (await Permission.storage.request()).isGranted;
    } else {
      return (await Permission.photos.request()).isGranted;
    }
  }

  @override
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  @override
  Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  @override
  Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  @override
  Future<bool> hasPhotosPermission() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.isGranted;
      if (photosStatus) return true;
      return await Permission.storage.isGranted;
    }
    return await Permission.photos.isGranted;
  }

  @override
  Future<bool> hasStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  @override
  Future<void> openDeviceSettings() async {
    await openAppSettings();
  }
}
