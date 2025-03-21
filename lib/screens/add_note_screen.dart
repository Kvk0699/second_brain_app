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
  final TextEditingController descriptionController = TextEditingController();
  bool _obscureContent = false;
  bool _isSaving = false;
  bool _accountNameError = false;
  bool _usernameError = false;
  bool _passwordError = false;

  @override
  void initState() {
    super.initState();
    id = widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    titleController.text = widget.note?.title ?? '';
    contentController.text = widget.note?.content ?? '';
    if (widget.note is NoteModel) {
      descriptionController.text = (widget.note as NoteModel).description;
    }
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
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (widget.isPasswordNote) {
      setState(() {
        _accountNameError = titleController.text.trim().isEmpty;
        _usernameError = usernameController.text.trim().isEmpty;
        _passwordError = contentController.text.trim().isEmpty;
      });

      if (_accountNameError || _usernameError || _passwordError) {
        return;
      }
    } else {
      if (titleController.text.trim().isEmpty &&
          contentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter title or content')),
        );
        return;
      }
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
              description: descriptionController.text.trim(),
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
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.isPasswordNote ? 'Password Note' : 'Note',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ),
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
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: titleController,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.isPasswordNote
                            ? '🔑 Account Name'
                            : '✏️ Title',
                        errorText: widget.isPasswordNote && _accountNameError
                            ? 'Account name is required'
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(16),
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
                      onChanged: (value) {
                        if (_accountNameError)
                          setState(() => _accountNameError = false);
                      },
                    ),
                  ),
                  if (widget.isPasswordNote)
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        hintText: '👤 Username',
                        errorText:
                            _usernameError ? 'Username is required' : null,
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
                      onChanged: (value) {
                        if (_usernameError)
                          setState(() => _usernameError = false);
                      },
                    ),
                  const Divider(height: 1),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.isPasswordNote
                        ? TextField(
                            controller: contentController,
                            maxLines: 1,
                            obscureText: _obscureContent,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              errorText: widget.isPasswordNote && _passwordError
                                  ? 'Password is required'
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.all(16),
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
                            onChanged: (value) {
                              if (_passwordError)
                                setState(() => _passwordError = false);
                            },
                          )
                        : TextFormField(
                            controller: contentController,
                            maxLines: null,
                            minLines: 100,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Start writing your thoughts here...',
                              errorText: widget.isPasswordNote && _passwordError
                                  ? 'Password is required'
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.all(16),
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
                            onChanged: (value) {
                              if (_passwordError)
                                setState(() => _passwordError = false);
                            },
                          ),
                  ),
                  if (widget.isPasswordNote) const Divider(height: 1),
                  if (widget.isPasswordNote)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        controller: descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 100,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: '📝 Add a brief description...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: '',
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.all(16),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
    );
  }
}
