import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio responsable de persistir de forma cifrada los tokens de sesión.
/// En Android usa EncryptedSharedPreferences (AES) y en iOS usa Keychain.
class TokenStorageService {
  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'atrio_access_token';
  static const String _keyRefreshToken = 'atrio_refresh_token';

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

  /// Guarda de forma segura el access token y el refresh token.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  /// Actualiza únicamente el access token (ej. tras un refresh).
  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
  }

  /// Obtiene el access token guardado.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Obtiene el refresh token guardado.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Elimina ambos tokens del almacenamiento seguro (ej. al hacer logout).
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  /// Comprueba si existe al menos un token guardado.
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
