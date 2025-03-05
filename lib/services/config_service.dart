import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/api_config_model.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final _storage = const FlutterSecureStorage();
  static const _apiConfigsKey = 'api_configs';
  static const _activeConfigIdKey = 'active_config_id';

  /// Initialize configuration
  Future<void> init() async {
    await dotenv.load();

    // Check if API configs are already stored
    final storedConfigs = await _storage.read(key: _apiConfigsKey);

    if (storedConfigs == null || storedConfigs.isEmpty) {
      // Store default API config on first run
      final envKey = dotenv.env['HUGGING_FACE_API_KEY'];
      if (envKey != null) {
        final defaultConfig = ApiConfigModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          provider: ApiProvider.huggingFace,
          apiKey: envKey,
          modelName: 'Qwen/Qwen2.5-72B-Instruct',
          baseUrl: 'https://api-inference.huggingface.co/models',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await saveApiConfig(defaultConfig);
        await setActiveConfig(defaultConfig.id);
      }
    }
  }

  /// Get all API configurations
  Future<List<ApiConfigModel>> getAllApiConfigs() async {
    try {
      final storedConfigs = await _storage.read(key: _apiConfigsKey);

      if (storedConfigs == null || storedConfigs.isEmpty) {
        return [];
      }

      final List<dynamic> decodedConfigs = json.decode(storedConfigs);
      return decodedConfigs
          .map((config) =>
              ApiConfigModel.fromJson(config as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching API configs: $e');
      return [];
    }
  }

  /// Get active API configuration
  Future<ApiConfigModel?> getActiveApiConfig() async {
    try {
      final activeId = await _storage.read(key: _activeConfigIdKey);
      if (activeId == null) return null;

      final configs = await getAllApiConfigs();
      if (configs.isEmpty) return null;

      // Try to find the active config by ID first
      try {
        return configs.firstWhere((config) => config.id == activeId);
      } catch (e) {
        // If not found, try to find any config marked as active
        try {
          return configs.firstWhere((config) => config.isActive);
        } catch (e) {
          // If no active config found, return the first one
          return configs.first;
        }
      }
    } catch (e) {
      debugPrint('Error getting active API config: $e');
      return null;
    }
  }

  /// Save an API configuration
  Future<bool> saveApiConfig(ApiConfigModel config) async {
    try {
      final configs = await getAllApiConfigs();
      final existingIndex = configs.indexWhere((c) => c.id == config.id);

      if (existingIndex >= 0) {
        configs[existingIndex] = config;
      } else {
        configs.add(config);
      }

      final configsJson = json.encode(configs.map((e) => e.toJson()).toList());
      await _storage.write(key: _apiConfigsKey, value: configsJson);

      // If this is the only config or is marked as active, set it as active
      if (configs.length == 1 || config.isActive) {
        await setActiveConfig(config.id);
      }

      return true;
    } catch (e) {
      debugPrint('Error saving API config: $e');
      return false;
    }
  }

  /// Update an existing API configuration
  Future<bool> updateApiConfig(ApiConfigModel config) async {
    try {
      final configs = await getAllApiConfigs();
      final existingIndex = configs.indexWhere((c) => c.id == config.id);

      if (existingIndex >= 0) {
        configs[existingIndex] = config;

        final configsJson =
            json.encode(configs.map((e) => e.toJson()).toList());
        await _storage.write(key: _apiConfigsKey, value: configsJson);

        // If this config was active, make sure it stays active
        final activeId = await _storage.read(key: _activeConfigIdKey);
        if (activeId == config.id && !config.isActive) {
          await setActiveConfig(config.id);
        }

        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error updating API config: $e');
      return false;
    }
  }

  /// Set active API configuration
  Future<bool> setActiveConfig(String configId) async {
    try {
      // Update active flag on all configs
      final configs = await getAllApiConfigs();
      for (int i = 0; i < configs.length; i++) {
        final isActive = configs[i].id == configId;
        if (configs[i].isActive != isActive) {
          configs[i] = configs[i].copyWith(
            isActive: isActive,
            updatedAt: DateTime.now(),
          );
        }
      }

      // Save updated configs
      final configsJson = json.encode(configs.map((e) => e.toJson()).toList());
      await _storage.write(key: _apiConfigsKey, value: configsJson);

      // Store active config ID
      await _storage.write(key: _activeConfigIdKey, value: configId);

      return true;
    } catch (e) {
      debugPrint('Error setting active API config: $e');
      return false;
    }
  }

  /// Delete an API configuration
  Future<bool> deleteApiConfig(String configId) async {
    try {
      final configs = await getAllApiConfigs();
      configs.removeWhere((config) => config.id == configId);

      final configsJson = json.encode(configs.map((e) => e.toJson()).toList());
      await _storage.write(key: _apiConfigsKey, value: configsJson);

      // If we deleted the active config, set a new one if available
      final activeId = await _storage.read(key: _activeConfigIdKey);
      if (activeId == configId && configs.isNotEmpty) {
        await setActiveConfig(configs.first.id);
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting API config: $e');
      return false;
    }
  }

  /// Clear all configurations
  Future<void> clearAllConfigs() async {
    await _storage.delete(key: _apiConfigsKey);
    await _storage.delete(key: _activeConfigIdKey);
  }
}
