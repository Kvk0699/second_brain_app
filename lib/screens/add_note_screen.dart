import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AddNoteScreen extends StatefulWidget {
  final Map<String, dynamic>? note;
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
  late String id;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  Timer? _autoSaveTimer;
  bool _obscureContent = false;

  @override
  void initState() {
    super.initState();
    id = widget.note?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    titleController.text = widget.note?['title'] ?? '';
    contentController.text = widget.note?['content'] ?? '';
    _obscureContent = widget.isPasswordNote;

    // Setup auto-save listeners
    titleController.addListener(_startAutoSave);
    contentController.addListener(_startAutoSave);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), _autoSaveNote);
  }

  Future<void> _autoSaveNote() async {
    if (titleController.text.trim().isEmpty &&
        contentController.text.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('notes') ?? '[]';
      final notes = List<Map<String, dynamic>>.from(
        json.decode(notesJson) as List,
      );

      final newNote = {
        'id': id,
        'title': titleController.text.trim(),
        'content': contentController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final index = notes.indexWhere((note) => note['id'] == id);
      if (index > -1) {
        notes[index] = newNote;
      } else {
        notes.insert(0, newNote);
      }

      await prefs.setString('notes', json.encode(notes));
    } catch (error) {
      debugPrint('Error auto-saving note: $error');
    }
  }

  Future<void> _deleteNote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('notes') ?? '[]';
      final notes = List<Map<String, dynamic>>.from(
        json.decode(notesJson) as List,
      );

      notes.removeWhere((note) => note['id'] == id);
      await prefs.setString('notes', json.encode(notes));
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error deleting note: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isPasswordNote ? 'Password Note' : 'Note',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Note'),
                    content: const Text(
                        'Are you sure you want to delete this note?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteNote();
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
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
                        counterText: '',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 20,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
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
                            ? 'Enter password and other details...'
                            : 'Start writing your thoughts here...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Auto-save indicator
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Auto-saving...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
