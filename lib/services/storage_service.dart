import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';

class StorageService {
  static const String _storageKey = 'items';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<List<ItemModel>> getAllItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString(_storageKey);

    if (itemsJson == null) return [];

    final List<dynamic> decodedItems = json.decode(itemsJson);
    return decodedItems
        .map((item) => ItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<T>> getItemsByType<T extends ItemModel>() async {
    final items = await getAllItems();
    return items.whereType<T>().toList();
  }

  Future<void> addItem(ItemModel item) async {
    final items = await getAllItems();
    items.insert(0, item);
    await _saveItems(items);
  }

  Future<void> updateItem(ItemModel updatedItem) async {
    final items = await getAllItems();
    final index = items.indexWhere((item) => item.id == updatedItem.id);

    if (index != -1) {
      items[index] = updatedItem;
      await _saveItems(items);
    }
  }

  Future<void> deleteItem(String id) async {
    final items = await getAllItems();
    items.removeWhere((item) => item.id == id);
    await _saveItems(items);
  }

  Future<void> _saveItems(List<ItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, itemsJson);
  }
}
