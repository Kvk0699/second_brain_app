import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import 'dart:async';
import '../widgets/delete_confirmation_dialog.dart';

class AddNoteScreen extends StatefulWidget {
  final ItemModel? note;
  final bool isPasswordNote;

  const AddNoteScreen({
    Key? key,
    this.note,
    this.isPasswordNote = false,
  }) : super(key: key);

  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final StorageService _storage = StorageService();
  late String id;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController usernameController =
      TextEditingController(); // For password notes
  bool _obscureContent = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    id = widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    titleController.text = widget.note?.title ?? '';
    contentController.text = widget.note?.content ?? '';
    if (widget.isPasswordNote && widget.note is PasswordModel) {
      usernameController.text = (widget.note as PasswordModel).username;
    }
    _obscureContent = widget.isPasswordNote;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (titleController.text.trim().isEmpty &&
        contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title or content')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final ItemModel newNote = widget.isPasswordNote
          ? PasswordModel(
              id: id,
              accountName: titleController.text.trim(),
              username: usernameController.text.trim(),
              password: contentController.text.trim(),
              createdAt: widget.note?.createdAt ?? now,
              updatedAt: now,
              isSecure: true,
            )
          : NoteModel(
              id: id,
              title: titleController.text.trim(),
              content: contentController.text.trim(),
              createdAt: widget.note?.createdAt ?? now,
              updatedAt: now,
            );

      if (widget.note != null) {
        await _storage.updateItem(newNote);
      } else {
        await _storage.addItem(newNote);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate successful save
      }
    } catch (error) {
      debugPrint('Error saving note: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving note')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteNote() async {
    try {
      await _storage.deleteItem(id);
      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate successful deletion
      }
    } catch (error) {
      debugPrint('Error deleting note: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting note')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isPasswordNote ? 'Password Note' : 'Note',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
        actions: [
          if (widget.isPasswordNote)
            IconButton(
              icon: Icon(
                _obscureContent ? Icons.visibility_off : Icons.visibility,
                color: Colors.blue,
              ),
              onPressed: () =>
                  setState(() => _obscureContent = !_obscureContent),
            ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DeleteConfirmationDialog(
                    title: 'Delete Note',
                    message: 'Are you sure you want to delete this note?',
                    onDelete: _deleteNote,
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.isPasswordNote
                            ? '🔑 Account Name'
                            : '✏️ Title',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                        filled: true,
                        fillColor: Colors.transparent,
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                          fontSize: 20,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (widget.isPasswordNote)
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: '👤 Username',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    TextField(
                      controller: contentController,
                      maxLines: widget.isPasswordNote ? 1 : null,
                      obscureText: _obscureContent,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.isPasswordNote
                            ? 'Enter password'
                            : 'Start writing your thoughts here...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: true,
                        fillColor: Colors.transparent,
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Save and Cancel buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveNote,
                    // style: ElevatedButton.styleFrom(
                    //   backgroundColor: Colors.blue,
                    //   foregroundColor: Colors.white,
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 24,
                    //     vertical: 12,
                    //   ),
                    // ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.note != null ? 'Update' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
