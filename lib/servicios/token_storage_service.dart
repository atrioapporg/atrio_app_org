import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio responsable de persistir de forma cifrada los tokens de sesión.
/// En Android usa EncryptedSharedPreferences (AES) y en iOS usa Keychain.
class TokenStorageService {
  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'atrio_access_token';
  static const String _keyRefreshToken = 'atrio_refresh_token';
  static const String _keyExpiresAt = 'atrio_token_expires_at';

  TokenStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              resetOnError: true,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Guarda de forma segura e inmediata el par de tokens (access_token y refresh_token)
  /// junto con su marca temporal de expiración (expires_at) si está disponible.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    if (expiresAt != null) {
      await _storage.write(
        key: _keyExpiresAt,
        value: expiresAt.toUtc().toIso8601String(),
      );
    }
  }

  /// Actualiza únicamente el access token y opcionalmente su fecha de expiración.
  Future<void> saveAccessToken(
    String accessToken, {
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (expiresAt != null) {
      await _storage.write(
        key: _keyExpiresAt,
        value: expiresAt.toUtc().toIso8601String(),
      );
    }
  }

  /// Guarda la marca temporal de expiración del access token.
  Future<void> saveTokenExpiry(DateTime expiresAt) async {
    await _storage.write(
      key: _keyExpiresAt,
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  /// Obtiene el access token guardado.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Obtiene el refresh token guardado.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Obtiene la fecha/hora de expiración del access token guardada (si existe).
  Future<DateTime?> getTokenExpiry() async {
    final raw = await _storage.read(key: _keyExpiresAt);
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) return parsed.toLocal();
    final epoch = int.tryParse(raw.trim());
    if (epoch != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        epoch > 1000000000000 ? epoch : epoch * 1000,
      );
    }
    return null;
  }

  /// Elimina los tokens y la fecha de expiración del almacenamiento seguro (ej. al hacer logout o expirar sesión).
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiresAt);
  }

  /// Borra absolutamente todos los registros y llaves de flutter_secure_storage
  /// (simulando una instalación limpia de cero en Android Keystore y iOS Keychain).
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Comprueba si existe al menos un token guardado.
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
