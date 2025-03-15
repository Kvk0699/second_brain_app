import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../utils/enums.dart';

class ItemListScreen extends StatefulWidget {
  final String title;
  final List<ItemModel> items;
  final Function(ItemModel) onItemTap;
  final Function() onAddItem;

  const ItemListScreen({
    Key? key,
    required this.title,
    required this.items,
    required this.onItemTap,
    required this.onAddItem,
  }) : super(key: key);

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ItemModel> _filteredItems = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _updateFilteredItems();
  }

  @override
  void didUpdateWidget(ItemListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update filtered items when widget.items changes
    if (oldWidget.items != widget.items) {
      _updateFilteredItems();
    }
  }

  void _updateFilteredItems() {
    setState(() {
      _filteredItems = List.from(widget.items);
    });
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final title = item.title.toLowerCase();
          final description = item is DocumentModel
              ? (item.description ?? '').toLowerCase()
              : item.content.toLowerCase();
          final searchLower = query.toLowerCase();

          return title.contains(searchLower) ||
              description.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title}...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: _filterItems,
              )
            : Text(widget.title),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  // _filteredItems = widget.items;
                  _filterItems('');
                });
              },
            ),
        ],
      ),
      body: _filteredItems.isEmpty
          ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No items available'
                    : 'No results found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return getItemWidget(item, widget.onItemTap);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await widget.onAddItem();
          if (result == true) {
            _updateFilteredItems();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
