import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _keySession = 'key_session';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveKeySession(String keySession) async {
    await _storage.write(key: _keySession, value: keySession);
  }

  Future<String?> getKeySession() async {
    return await _storage.read(key: _keySession);
  }

  Future<void> clearKeySession() async {
    await _storage.delete(key: _keySession);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> isAuthenticated() async {
    final keySession = await getKeySession();
    return keySession != null && keySession.isNotEmpty;
  }
}
