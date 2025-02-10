import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_note_screen.dart';
import '../utils/llm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> notes = [];
  String searchQuery = '';
  String question = '';
  String answer = '';
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotes = prefs.getString('notes');
      if (savedNotes != null) {
        setState(() {
          notes = List<Map<String, dynamic>>.from(
            json.decode(savedNotes) as List,
          );
        });
      }
    } catch (error) {
      debugPrint('Error loading notes: $error');
    }
  }

  List<Map<String, dynamic>> get filteredNotes {
    return notes.where((note) {
      final title = note['title'].toString().toLowerCase();
      final content = note['content'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return title.contains(query) || content.contains(query);
    }).toList();
  }

  String buildPromptWithNotes(
      String userQuestion, List<Map<String, dynamic>> allNotes) {
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

    final notesContext = allNotes.asMap().entries.map((entry) {
      final idx = entry.key;
      final note = entry.value;
      return '''
        Note #${idx + 1}:
        Title: "${note['title']}"
        Content: "${note['content']}"
      ''';
    }).join('\n\n');

    return '''
      You are a friendly and secure personal assistant managing the user's digital notebook. 
      This notebook contains sensitive personal information like passwords, account details, private notes, bill payment dates, and subscription details.
      
      Current Date: $currentDate
      Current Time: $currentTime

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

      The user question is: "$userQuestion"

      Now provide a concise, direct answer following the guidelines above.
    ''';
  }

  Future<void> handleAsk() async {
    final trimmedQuestion = questionController.text.trim();
    if (trimmedQuestion.isEmpty || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prompt = buildPromptWithNotes(trimmedQuestion, notes);
      final llmResponse = await LLMService().getAnswerFromLLM(prompt);

      setState(() {
        answer = llmResponse;
        question = '';
        questionController.clear();
      });
    } catch (error) {
      setState(() {
        answer = 'Something went wrong while fetching your answer.';
      });
      debugPrint('Error while asking LLM: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: '🔎 Search notes...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            builder: (context) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.note_add_rounded,
                                        color: Colors.blue),
                                    title: const Text('Create New Note'),
                                    onTap: () {
                                      Navigator.pop(
                                          context); // Close bottom sheet
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddNoteScreen(),
                                        ),
                                      ).then((_) => loadNotes());
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.password_rounded,
                                        color: Colors.blue),
                                    title: const Text('Add New Password'),
                                    onTap: () {
                                      Navigator.pop(
                                          context); // Close bottom sheet
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddNoteScreen(
                                            isPasswordNote: true,
                                          ),
                                        ),
                                      ).then((_) => loadNotes());
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.add_box_rounded,
                          size: 48,
                          color: Colors.blue,
                        )),
                  ),
                ],
              ),
            ),

            // Notes grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddNoteScreen(note: note),
                        ),
                      ).then((_) => loadNotes());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              note['content'] ?? 'No content',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateTime.parse(note['timestamp'])
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Ask section at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (answer.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 30),
                            child: Text(answer),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.grey.shade600),
                              onPressed: () => setState(() => answer = ''),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isLoading)
                    Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Text(
                            '🤔 Thinking...',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: questionController,
                          decoration: InputDecoration(
                            hintText: '🤖 Ask your second brain...',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => handleAsk(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: handleAsk,
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ],
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
