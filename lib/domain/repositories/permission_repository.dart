abstract class PermissionRepository {
  Future<bool> requestMicrophonePermission();

  Future<bool> requestCameraPermission();

  Future<bool> requestPhotosPermission();

  Future<bool> requestStoragePermission();

  Future<bool> hasMicrophonePermission();

  Future<bool> hasCameraPermission();

  Future<bool> hasPhotosPermission();

  Future<bool> hasStoragePermission();
  
  Future<void> openDeviceSettings();
}
