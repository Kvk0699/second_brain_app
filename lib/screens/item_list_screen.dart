import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../utils/enums.dart';

class ItemListScreen extends StatelessWidget {
  final String title;
  final List<ItemModel> items;
  final Function(ItemModel) onItemTap;

  const ItemListScreen({
    Key? key,
    required this.title,
    required this.items,
    required this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return getItemWidget(item, onItemTap);
        },
      ),
    );
  }
}
