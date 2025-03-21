import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../utils/llm_service.dart';
import '../models/reference_model.dart';

class HomeController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<ItemModel> items = [];
  String searchQuery = '';
  String answer = '';
  bool isLoading = false;
  String parsedAnswer = '';
  List<ItemReference> references = [];

  // Theme management
  static const String themePreferenceKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  HomeController() {
    _loadThemePreference();
    _initializeDummyData();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(themePreferenceKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themePreferenceKey, _themeMode.toString());

    notifyListeners();
  }

  // Getters for filtered lists
  List<ItemModel> get filteredItems {
    final query = searchQuery.toLowerCase();
    return items.where((item) {
      final title = item.title.toLowerCase();
      final content = item.content.toLowerCase();
      return title.contains(query) ||
          content.contains(query) ||
          item is EventModel ||
          item is PasswordModel;
    }).toList();
  }

  List<ItemModel> get notesList =>
      filteredItems.where((item) => item is NoteModel).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<ItemModel> get passwordsList =>
      filteredItems.where((item) => item is PasswordModel).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<ItemModel> get eventsList =>
      filteredItems.where((item) => item is EventModel).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<ItemModel> get documentsList =>
      filteredItems.where((item) => item is DocumentModel).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<ItemModel> get upcomingEvents {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return eventsList.where((item) {
      if (item is EventModel) {
        final eventDate = item.eventDateTime;
        return true;
      }
      return false;
    }).toList()
      ..sort((a, b) => (a as EventModel)
          .eventDateTime
          .compareTo((b as EventModel).eventDateTime));
  }

  // Data management methods
  Future<void> loadNotes() async {
    try {
      final loadedItems = await _storage.getAllItems();
      items = loadedItems;
      notifyListeners();
    } catch (error) {
      debugPrint('Error loading items: $error');
    }
  }

  Future<void> deleteItem(String id) async {
    await _storage.deleteItem(id);
    await loadNotes(); // Reload notes after deletion
  }

  Future<void> addItem(ItemModel item) async {
    await _storage.addItem(item);
    await loadNotes(); // Reload notes after addition
  }

  Future<void> updateItem(ItemModel item) async {
    await _storage.updateItem(item);
    await loadNotes(); // Reload notes after update
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  // Chat related methods
  void clearAnswer() {
    answer = '';
    parsedAnswer = '';
    references = [];
    notifyListeners();
  }

  // Modify the buildPromptWithNotes method to include item IDs
  String buildPromptWithNotes(
      String userQuestion, List<ItemModel> allItems, BuildContext context) {
    final now = DateTime.now();
    final currentDate = now.toLocal().toString().split(' ')[0];
    final currentTime = TimeOfDay.fromDateTime(now).format(context);

    if (allItems.isEmpty) {
      return '''
        You are a personal assistant managing the user's secure digital notebook called Second Brain.
        Current Date: $currentDate
        Current Time: $currentTime
        
        The user question is: "$userQuestion"
        Since there are no notes available, respond with:
        "I don't see any notes in your Second Brain yet. Feel free to add some information and I'll be happy to help you recall it."
      ''';
    }

    // Separate items by type for better context organization
    final notes = allItems.whereType<NoteModel>().toList();
    final passwords = allItems.whereType<PasswordModel>().toList();
    final events = allItems.whereType<EventModel>().toList();
    final documents = allItems.whereType<DocumentModel>().toList();

    // Build context for notes with IDs
    final notesContext = notes.isEmpty
        ? "No notes stored."
        : notes.asMap().entries.map((entry) => '''
          Note #${entry.key + 1}:
          ID: "${entry.value.id}"
          Title: "${entry.value.title}"
          Content: "${entry.value.content}"
          Last Updated: ${entry.value.updatedAt.toLocal().toString().split('.')[0]}
        ''').join('\n\n');

    // Build context for passwords with IDs
    final passwordsContext = passwords.isEmpty
        ? "No passwords stored."
        : passwords.asMap().entries.map((entry) => '''
        Password #${entry.key + 1}:
        ID: "${entry.value.id}"
        Account: "${entry.value.accountName}"
        Username: "${entry.value.username}"
        Last Updated: ${entry.value.updatedAt.toLocal().toString().split('.')[0]}
      ''').join('\n\n');

    // Build context for events with IDs and calculated time remaining
    final eventsContext = events.isEmpty
        ? "No events stored."
        : events.asMap().entries.map((entry) {
            final event = entry.value;
            final daysRemaining = event.eventDateTime.difference(now).inDays;
            final hoursRemaining =
                event.eventDateTime.difference(now).inHours % 24;
            String timeStatus;

            if (event.eventDateTime.isBefore(now)) {
              timeStatus = "Past event (${-daysRemaining} days ago)";
            } else if (daysRemaining == 0) {
              timeStatus = "Today (in ${hoursRemaining} hours)";
            } else if (daysRemaining == 1) {
              timeStatus = "Tomorrow (in ${daysRemaining} day)";
            } else {
              timeStatus = "Upcoming (in ${daysRemaining} days)";
            }

            return '''
              Event #${entry.key + 1}:
              ID: "${event.id}"
              Title: "${event.title}"
              Description: "${event.description}"
              Date: ${event.eventDateTime.toLocal().toString().split('.')[0]}
              Status: $timeStatus
            ''';
          }).join('\n\n');

    // Build context for documents
    final documentsContext = documents.isEmpty
        ? "No documents stored."
        : documents.asMap().entries.map((entry) {
            final doc = entry.value;
            return '''
              Document #${entry.key + 1}:
              ID: "${doc.id}"
              Title: "${doc.title}"
              Description: "${doc.description ?? 'No description'}"
              File Type: "${doc.fileExtension ?? 'Unknown'}"
              File Size: ${_formatFileSize(doc.fileSize)}
              Last Updated: ${doc.updatedAt.toLocal().toString().split('.')[0]}
            ''';
          }).join('\n\n');

    return '''
      You are a personal assistant managing the user's digital notebook called Second Brain. 
      This notebook contains sensitive personal information including notes, password details, scheduled events, and documents.
      
      Current Date: $currentDate
      Current Time: $currentTime

      Guidelines for your responses:
        1. Be professional and brief in your answers, avoiding emoji usage.
        2. Use ONLY information found in the user's data. For questions without relevant data, say:
          "I don't have any information about that in your Second Brain yet."
        3. When sharing sensitive information like passwords:
          - Only show the specific details that were asked for
          - Confirm that you're sharing sensitive information
        4. Format dates, times, and account details in an easily readable way
        5. Never invent or guess information not present in the stored data
        6. For questions about events:
          - Indicate whether events are upcoming, happening today, or in the past
          - For upcoming events, mention how many days are left
        7. For searches across multiple types of data, prioritize the most relevant information first
        8. IMPORTANT: When referencing specific notes, passwords, or events, include their ID in a special tag format:
           - For notes: [[note:ID|Title]]
           - For passwords: [[password:ID|Account Name]]
           - For events: [[event:ID|Title]]
           - For documents: [[document:ID|Title]]
        9. Use Markdown formatting for improved readability
           
      STORED NOTES:
      $notesContext

      STORED PASSWORDS:
      $passwordsContext

      STORED EVENTS:
      $eventsContext
      
      STORED DOCUMENTS:
      $documentsContext

      The user question is: "$userQuestion"

      Now provide a concise, direct answer using only the information available above. Utilize appropriate Markdown formatting for clarity and readability.
  ''';
  }

  // Add a new class to represent a reference
  Future<void> handleAsk(String question, BuildContext context) async {
    if (question.trim().isEmpty || isLoading) return;

    isLoading = true;
    references = []; // Clear previous references
    parsedAnswer = ''; // Clear previous parsed answer
    notifyListeners();

    try {
      final prompt = buildPromptWithNotes(question, items, context);
      final llmResponse = await LLMService().getAnswerFromLLM(prompt);
      answer = llmResponse;

      // Parse the response to find and process references
      parseResponseWithReferences(llmResponse);
    } catch (error) {
      answer = 'An error occurred: ${error.toString().split('\n')[0]}';
      parsedAnswer = answer;
      debugPrint('Error while asking LLM: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Parse the LLM response to find and process references
  void parseResponseWithReferences(String response) {
    // Regular expression to find references in the format [[type:id|title]]
    final referenceRegex =
        RegExp(r'\[\[(note|password|event|document):([^|]+)\|([^\]]+)\]\]');

    // Find all matches
    final matches = referenceRegex.allMatches(response);

    // If no references found, set parsedAnswer to the original response
    if (matches.isEmpty) {
      parsedAnswer = response;
      return;
    }

    // Extract references and replace them with markable text
    String processedText = response;
    int index = 0;

    for (final match in matches) {
      final fullMatch = match.group(0) ?? '';
      final type = match.group(1) ?? '';
      final id = match.group(2) ?? '';
      final title = match.group(3) ?? '';

      // Create a reference object
      references.add(ItemReference(
        id: id,
        title: title,
        type: _getReferenceType(type),
        index: index++,
      ));

      // Replace the reference in the text with a clickable marker
      processedText =
          processedText.replaceFirst(fullMatch, '[$title](#ref-$id)');
    }

    parsedAnswer = processedText;
  }

  // Helper method to convert string type to enum
  ReferenceType _getReferenceType(String type) {
    switch (type.toLowerCase()) {
      case 'note':
        return ReferenceType.note;
      case 'password':
        return ReferenceType.password;
      case 'event':
        return ReferenceType.event;
      case 'document':
        return ReferenceType.document;
      default:
        return ReferenceType.note;
    }
  }

  // Helper method for file size formatting
  String _formatFileSize(int? fileSize) {
    if (fileSize == null) return "Unknown";

    final kb = fileSize / 1024;
    if (kb < 1024) {
      return "${kb.toStringAsFixed(2)} KB";
    } else {
      final mb = kb / 1024;
      return "${mb.toStringAsFixed(2)} MB";
    }
  }

  // Method to find an item by ID
  ItemModel? findItemById(String id) {
    return items.firstWhere(
      (item) => item.id == id,
      orElse: () =>
          null as ItemModel, // This will throw, but we handle it in the UI
    );
  }

  Future<void> initializeTheme() async {
    await _loadThemePreference();
  }

  Future<void> _initializeDummyData() async {
    // Create dummy items
    final dummyItems = [
      // Two Note Models
      NoteModel(
        id: '1',
        title: 'Meeting Notes',
        content: 'Discuss project timeline and resource allocation for Q2.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        description: '',
      ),
      NoteModel(
        id: '2',
        title: 'Shopping List',
        content: 'Milk, eggs, bread, fruits, vegetables, and coffee beans.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        description: '',
      ),

      // Two Password Models
      PasswordModel(
        id: '3',
        accountName: 'Gmail Account',
        username: 'user@gmail.com',
        password: 'securePass2024!',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      PasswordModel(
        id: '4',
        accountName: 'Netflix',
        username: 'user.netflix',
        password: 'streamingPass#123',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),

      // Two Event Models
      EventModel(
        id: '5',
        title: 'Team Meeting',
        description: 'Quarterly review with the development team.',
        eventDateTime: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      EventModel(
        id: '6',
        title: 'Dentist Appointment',
        description: 'Regular check-up at Downtown Dental Clinic.',
        eventDateTime: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];

    // Check if any items already exist
    final existingItems = await _storage.getAllItems();

    // Only initialize with dummy data if the storage is empty
    if (existingItems.isEmpty) {
      // Add each item to storage
      for (final item in dummyItems) {
        await _storage.addItem(item);
      }

      // Load the items from storage
      await loadNotes();
    }
  }
}
