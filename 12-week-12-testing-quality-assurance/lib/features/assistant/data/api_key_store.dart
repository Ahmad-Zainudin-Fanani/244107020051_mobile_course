import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kontrak penyimpanan API key.
///
/// Dipisah dari implementasi supaya test tidak membutuhkan platform channel
/// Android/iOS.
abstract class ApiKeyStore {
  Future<String?> read();
  Future<void> save(String apiKey);
  Future<void> delete();
}

/// Menyimpan API key di secure storage perangkat (Keystore/Keychain).
///
/// Key tidak pernah ditulis ke kode sumber, file konfigurasi, atau repo.
class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Nama entri di secure storage.
  static const storageKey = 'gemini_api_key';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final value = await _storage.read(key: storageKey);
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  Future<void> save(String apiKey) {
    return _storage.write(key: storageKey, value: apiKey.trim());
  }

  @override
  Future<void> delete() => _storage.delete(key: storageKey);
}
