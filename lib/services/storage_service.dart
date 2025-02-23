import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/item_model.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const String _storageKey = 'items';

  // Create storage instance with iOS and Android options
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Uses EncryptedSharedPreferences
      sharedPreferencesName: 'secure_prefs',
      // Requires API level 23 and above
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
  );

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<List<ItemModel>> getAllItems() async {
    try {
      final String? itemsJson = await _storage.read(key: _storageKey);

      if (itemsJson == null || itemsJson.isEmpty) return [];

      final List<dynamic> decodedItems = json.decode(itemsJson);
      return decodedItems
          .map((item) => ItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching items: $e');
      return [];
    }
  }

  Future<List<T>> getItemsByType<T extends ItemModel>() async {
    final items = await getAllItems();
    return items.whereType<T>().toList();
  }

  Future<bool> addItem(ItemModel item) async {
    try {
      final items = await getAllItems();
      items.insert(0, item);
      return await _saveItems(items);
    } catch (e) {
      debugPrint('Error adding item: $e');
      return false;
    }
  }

  Future<bool> updateItem(ItemModel updatedItem) async {
    try {
      final items = await getAllItems();
      final index = items.indexWhere((item) => item.id == updatedItem.id);

      if (index != -1) {
        items[index] = updatedItem;
        return await _saveItems(items);
      }
      return false;
    } catch (e) {
      debugPrint('Error updating item: $e');
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      final items = await getAllItems();
      items.removeWhere((item) => item.id == id);
      return await _saveItems(items);
    } catch (e) {
      debugPrint('Error deleting item: $e');
      return false;
    }
  }

  Future<bool> _saveItems(List<ItemModel> items) async {
    try {
      final itemsJson = json.encode(items.map((e) => e.toJson()).toList());
      await _storage.write(key: _storageKey, value: itemsJson);
      return true;
    } catch (e) {
      debugPrint('Error saving items: $e');
      return false;
    }
  }

  // Clear all data (useful for logout)
  Future<void> clearAllData() async {
    await _storage.delete(key: _storageKey);
  }
}
