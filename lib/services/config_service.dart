import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final _storage = const FlutterSecureStorage();
  static const _apiKeyKey = 'hugging_face_api_key';
  
  /// Initialize configuration
  Future<void> init() async {
    await dotenv.load();
    
    // Check if API key is already stored securely
    final storedKey = await _storage.read(key: _apiKeyKey);
    if (storedKey == null) {
      // Store API key securely on first run
      final envKey = dotenv.env['HUGGING_FACE_API_KEY'];
      if (envKey != null) {
        await _storage.write(key: _apiKeyKey, value: envKey);
      }
    }
  }

  /// Get API key from secure storage
  Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: _apiKeyKey);
    } catch (e) {
      // Fallback to env file if secure storage fails
      return dotenv.env['HUGGING_FACE_API_KEY'];
    }
  }

  /// Update API key (useful for runtime updates)
  Future<void> updateApiKey(String newKey) async {
    await _storage.write(key: _apiKeyKey, value: newKey);
  }

  /// Clear stored configuration
  Future<void> clearConfig() async {
    await _storage.delete(key: _apiKeyKey);
  }
}
