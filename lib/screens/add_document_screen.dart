import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../controllers/home_controller.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../widgets/delete_confirmation_dialog.dart';

class AddDocumentScreen extends StatefulWidget {
  final DocumentModel? document;

  const AddDocumentScreen({
    Key? key,
    this.document,
  }) : super(key: key);

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final StorageService _storage = StorageService();

  File? _selectedFile;
  bool _isLoading = false;
  bool _titleError = false;
  bool _fileError = false;

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      _titleController.text = widget.document!.title;
      _descriptionController.text = widget.document!.description ?? '';
      if (widget.document!.filePath != null) {
        _selectedFile = File(widget.document!.filePath!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'txt', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Delete Document',
        message: 'Are you sure you want to delete this document?',
        onDelete: () async {
          if (widget.document != null) {
            await _storage.deleteDocument(widget.document!);
            if (mounted) {
              Navigator.pop(context, true);
            }
          }
        },
      ),
    );
  }

  Future<void> _updateDocument() async {
    if (!mounted) return;

    setState(() {
      _titleError = _titleController.text.trim().isEmpty;
    });

    if (_titleError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedFile != null &&
          _selectedFile!.path != widget.document!.filePath) {
        // First delete the old file
        await _storage.deleteDocument(widget.document!);

        // Then save as new document but keep the same ID
        await _storage.saveDocument(
          _selectedFile!,
          _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          id: widget.document!.id, // Pass the existing ID
        );
      } else {
        // No new file, just update metadata
        final updatedDoc = DocumentModel(
          id: widget.document!.id,
          title: _titleController.text.trim(),
          filePath: widget.document!.filePath!,
          fileExtension: widget.document!.fileExtension!,
          fileSize: widget.document!.fileSize!,
          description: _descriptionController.text.trim(),
          createdAt: widget.document!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _storage.updateItem(updatedDoc);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating document: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveDocument() async {
    if (!mounted) return;

    setState(() {
      _titleError = _titleController.text.trim().isEmpty;
      _fileError = _selectedFile == null;
    });

    if (_titleError || _fileError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _storage.saveDocument(
        _selectedFile!,
        _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving document: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.document != null ? 'Edit Document' : 'Add Document',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (widget.document != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _showDeleteConfirmation,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'Enter document title',
                  errorText: _titleError ? 'Title is required' : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _titleError
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.title,
                    color: _titleError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                onChanged: (value) {
                  if (_titleError) {
                    setState(() => _titleError = false);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter document description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(
                    Icons.description,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_fileError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select a file',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (_selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.insert_drive_file,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected File',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  p.basename(_selectedFile!.path),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<int>(
                        future: _selectedFile!.length(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final kb = snapshot.data! / 1024;
                            final size = kb < 1024
                                ? '${kb.toStringAsFixed(2)} KB'
                                : '${(kb / 1024).toStringAsFixed(2)} MB';

                            return Text(
                              'Size: $size',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            );
                          }
                          return const Text('Size: Calculating...');
                        },
                      ),
                      Text(
                        'Type: ${p.extension(_selectedFile!.path).toUpperCase().replaceFirst('.', '')}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select File'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading
                          ? null
                          : widget.document != null
                              ? _updateDocument
                              : _saveDocument,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : widget.document != null
                              ? const Text('Update Document')
                              : const Text('Add Document'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
