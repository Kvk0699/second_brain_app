import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../utils/llm_service.dart';

class HomeController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<ItemModel> items = [];
  String searchQuery = '';
  String answer = '';
  bool isLoading = false;

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
    notifyListeners();
  }

  Future<void> handleAsk(String question, BuildContext context) async {
    if (question.trim().isEmpty || isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      final prompt = buildPromptWithNotes(question, items, context);
      final llmResponse = await LLMService().getAnswerFromLLM(prompt);
      answer = llmResponse;
    } catch (error) {
      answer = 'Something went wrong while fetching your answer.';
      debugPrint('Error while asking LLM: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String buildPromptWithNotes(
      String userQuestion, List<ItemModel> allItems, BuildContext context) {
    final now = DateTime.now();
    final currentDate = now.toLocal().toString().split(' ')[0];
    final currentTime = TimeOfDay.fromDateTime(now).format(context);

    if (allItems.isEmpty) {
      return '''
        You are a friendly personal assistant managing the user's secure digital notebook.
        Current Date: $currentDate
        Current Time: $currentTime
        
        The user question is: "$userQuestion"
        Since there are no notes available, respond with:
        "I don't see any notes yet! 📝 Feel free to add some information and I'll be happy to help you recall it."
      ''';
    }

    // Separate items by type for better context organization
    final notes = allItems.whereType<NoteModel>().toList();
    final passwords = allItems.whereType<PasswordModel>().toList();
    final events = allItems.whereType<EventModel>().toList();

    // Build context for notes
    final notesContext = notes.isEmpty
        ? "No notes stored."
        : notes.asMap().entries.map((entry) => '''
          Note #${entry.key + 1}:
          Title: "${entry.value.title}"
          Content: "${entry.value.content}"
          Last Updated: ${entry.value.updatedAt.toLocal().toString().split('.')[0]}
        ''').join('\n\n');

    // Build context for passwords
    final passwordsContext = passwords.isEmpty
        ? "No passwords stored."
        : passwords.asMap().entries.map((entry) => '''
        Password #${entry.key + 1}:
        Account: "${entry.value.accountName}"
        Username: "${entry.value.username}"
        Password: "${entry.value.content}"
        Last Updated: ${entry.value.updatedAt.toLocal().toString().split('.')[0]}
      ''').join('\n\n');

    // Build context for events with calculated time remaining
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
              Title: "${event.title}"
              Description: "${event.description}"
              Date: ${event.eventDateTime.toLocal().toString().split('.')[0]}
              Status: $timeStatus
            ''';
          }).join('\n\n');

    return '''
      You are a friendly and secure personal assistant managing the user's digital notebook. 
      This notebook contains sensitive personal information including notes, password details, and scheduled events.
      
      Current Date: $currentDate
      Current Time: $currentTime

      Guidelines for your responses:
        1. Be warm and personal, but brief and direct in your answers.
        2. Use ONLY information found in the user's data. For questions without relevant data, say:
          "I don't have any information about that in your notes yet! 📝"
        3. When sharing sensitive information like passwords:
          - Only show the specific details that were asked for
          - Confirm that you're sharing sensitive information
        4. Format dates, times, and account details in an easily readable way
        5. Never invent or guess information not present in the stored data
        6. For questions about events:
          - Indicate whether events are upcoming, happening today, or in the past
          - For upcoming events, mention how many days are left
        7. For searches across multiple types of data, prioritize the most relevant information first

      STORED NOTES:
      $notesContext

      STORED PASSWORDS:
      $passwordsContext

      STORED EVENTS:
      $eventsContext

      The user question is: "$userQuestion"

      Now provide a concise, direct answer using only the information available above. Use Markdown formatting for clarity.
  ''';
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
