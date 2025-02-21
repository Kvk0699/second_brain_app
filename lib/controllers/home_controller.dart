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
      return title.contains(query) || content.contains(query);
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
      String userQuestion, List<ItemModel> allNotes, BuildContext context) {
    final now = DateTime.now();
    final currentDate = now.toLocal().toString().split(' ')[0];
    final currentTime = TimeOfDay.fromDateTime(now).format(context);

    if (allNotes.isEmpty) {
      return '''
        You are a friendly personal assistant managing the user's secure digital notebook.
        Current Date: $currentDate
        Current Time: $currentTime
        
        The user question is: "$userQuestion"
        Since there are no notes available, respond with:
        "I don't see any notes yet! 📝 Feel free to add some information and I'll be happy to help you recall it."
      ''';
    }

    // TODO: Implement full prompt building logic
    final notesContext = allNotes.asMap().entries.map((entry) => '''
        Note #${entry.key + 1}:
        Title: "${entry.value.title}"
        Content: "${entry.value.content}"
      ''').join('\n\n');

    return '''
      You are a friendly and secure personal assistant managing the user's digital notebook. 
      This notebook contains sensitive personal information like passwords, account details, private notes, bill payment dates, and subscription details.
      
      Current Date: ${currentDate}
      Current Time: ${currentTime}

      Guidelines for your responses:
        1. Be warm and personal, but brief and direct in your answers.
        2. Use ONLY information found in the notes. For questions without relevant data in notes, say:
          "I don't have any information about that in your notes yet! 📝"
        3. When sharing sensitive information like passwords or account details:
          - Only show the specific details that were asked for
        4. Format numbers, dates, and account details in an easily readable way
        5. Use appropriate emojis to make responses friendly (but don't overdo it)
        6. Never invent or guess information not present in the notes
        7. For questions about due dates or subscriptions:
          - Compare with current date to indicate if something is upcoming, due soon, or overdue
          - For upcoming payments or renewals, mention how many days are left

      The user's secure notes:
      $notesContext

      The user question is: "${userQuestion}"

      Now provide a concise, direct answer following the guidelines above.''';
  }

  Future<void> initializeTheme() async {
    await _loadThemePreference();
  }
}
