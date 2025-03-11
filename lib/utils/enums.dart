import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../widgets/event_display_widget.dart';
import '../widgets/note_display_widget.dart';
import '../widgets/password_display_widget.dart';
import '../widgets/document_display_widget.dart';

enum AddOption { note, password, event, document }

extension AddOptionExtension on AddOption {
  String get name {
    switch (this) {
      case AddOption.note:
        return 'Create New Note';
      case AddOption.password:
        return 'Add New Password';
      case AddOption.event:
        return 'Add New Event';
      case AddOption.document:
        return 'Add New Document';
    }
  }

  IconData get icon {
    switch (this) {
      case AddOption.note:
        return Icons.note_add_rounded;
      case AddOption.password:
        return Icons.password_rounded;
      case AddOption.event:
        return Icons.event;
      case AddOption.document:
        return Icons.upload_file_outlined;
    }
  }
}

Widget getItemWidget(ItemModel? item, Function(ItemModel) onItemTap) {
  if (item == null) {
    return const SizedBox.shrink();
  }
  if (item is NoteModel) {
    return NoteDisplayWidget(item: item, onItemTap: onItemTap);
  } else if (item is PasswordModel) {
    return PasswordDisplayWidget(item: item, onItemTap: onItemTap);
  } else if (item is EventModel) {
    return EventDisplayWidget(item: item, onItemTap: onItemTap);
  } else if (item is DocumentModel) {
    return DocumentDisplayWidget(item: item, onItemTap: onItemTap);
  }
  return const SizedBox.shrink();
}
