import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as local_auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io' show Platform;

import '../utils/enums.dart';
import '../widgets/note_display_widget.dart';
import 'add_note_screen.dart';
import '../widgets/add_event_widget.dart';
import '../models/item_model.dart';
import 'item_list_screen.dart';
import '../controllers/home_controller.dart';
import '../models/reference_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final _localAuthentication = LocalAuthentication();
  bool _isUserAuthorized = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadNotes();
    });
  }

  Future<void> authenticateUser(HomeController controller) async {
    bool isAuthorized = false;
    try {
      isAuthorized = await _localAuthentication.authenticate(
        localizedReason: "Please authenticate to see your passwords",
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: false,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (exception) {
      if (exception.code == local_auth_error.notAvailable ||
          exception.code == local_auth_error.passcodeNotSet ||
          exception.code == local_auth_error.notEnrolled) {
        // Show enhanced dialog with biometric enrollment option
        final action = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Authentication Required'),
              content: const Text(
                  'Biometric authentication is not set up on this device. What would you like to do?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Go Back'),
                  onPressed: () => Navigator.pop(context, 'back'),
                ),
                TextButton(
                  child: const Text('Set Up Biometrics'),
                  onPressed: () => Navigator.pop(context, 'setup'),
                ),
                FilledButton(
                  child: const Text('Continue Anyway'),
                  onPressed: () => Navigator.pop(context, 'continue'),
                ),
              ],
            );
          },
        );

        switch (action) {
          case 'setup':
            try {
              AppSettings.openAppSettings(type: AppSettingsType.security);
            } catch (e) {
              debugPrint('Error opening settings: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open device settings'),
                ),
              );
            }
            break;
          case 'continue':
            _navigateToPasswordList(context, controller);
            break;
          case 'back':
          default:
            // Do nothing, dialog is dismissed
            break;
        }
        return;
      }
    }

    if (!mounted) return;

    if (isAuthorized) {
      _navigateToPasswordList(context, controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) => Scaffold(
        appBar: _buildAppBar(context, controller),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchSection(controller),
              _buildListsSection(controller),
              _buildAskSection(controller),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, HomeController controller) {
    return AppBar(
      title: Text(
        'Second Brain',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _showSettingsMenu(context, controller),
        ),
      ],
    );
  }

  void _showSettingsMenu(BuildContext context, HomeController controller) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 100,
        100,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.brightness_6_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                'Dark Mode',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          onTap: controller.toggleTheme,
        ),
      ],
    );
  }

  Widget _buildSearchSection(HomeController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              textAlign: TextAlign.start,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 48),
                isDense: true,
              ),
              onChanged: controller.updateSearchQuery,
            ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: _showAddOptionsSheet,
      ),
    );
  }

  Widget _buildDashboardSection(HomeController controller) {
    if (controller.upcomingEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upcoming_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Upcoming Events',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...controller.upcomingEvents
              .map((event) => _buildUpcomingEventTile(event as EventModel)),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventTile(EventModel event) {
    final now = DateTime.now();
    final isToday = event.eventDateTime.day == now.day;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isToday ? Icons.today : Icons.event,
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.tertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TimeOfDay.fromDateTime(event.eventDateTime).format(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(
                isToday ? 'Today' : 'Tomorrow',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListsSection(HomeController controller) {
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        children: [
          // _buildDashboardSection(controller),
          if (controller.passwordsList.isNotEmpty)
            _buildPasswordSection(controller),
          if (controller.eventsList.isNotEmpty) _buildEventsSection(controller),
          if (controller.notesList.isNotEmpty) _buildNotesSection(controller),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(HomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        tileColor: Theme.of(context).colorScheme.tertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          'Passwords',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          Icons.visibility_off_rounded,
          color: Theme.of(context).colorScheme.surface,
        ),
        onTap: () {
          authenticateUser(controller);
        },
      ),
    );
  }

  Widget _buildNotesSection(HomeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            "Notes",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: controller.notesList.length,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            return NoteDisplayWidget(
              item: controller.notesList[index] as NoteModel,
              onItemTap: (note) {
                _handleNoteItemTap(
                    note: controller.notesList[index] as NoteModel);
              },
            );
          },
        )
      ],
    );
  }

  Widget _buildEventsSection(HomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
          tileColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            'Events',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(
            Icons.arrow_right_outlined,
            color: Theme.of(context).colorScheme.surface,
          ),
          onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemListScreen(
                    title: "Events",
                    items: controller.eventsList,
                    onItemTap: (note) {
                      if (note is EventModel) {
                        _showEventBottomSheet(context, eventNote: note);
                      }
                    },
                  ),
                ),
              )),
    );
  }

  Widget _buildAskSection(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          if (controller.answer.isNotEmpty) _buildAnswerBox(controller),
          if (controller.isLoading) _buildLoadingIndicator(),
          _buildQuestionInput(controller),
        ],
      ),
    );
  }

Widget _buildAnswerBox(HomeController controller) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Answer header with avatar and close button
        Padding(
            padding:
                const EdgeInsets.only(right: 8, left: 16, top: 12, bottom: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Assistant',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7),
                ),
                onPressed: controller.clearAnswer,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),

        // Divider
        Divider(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          height: 1,
        ),

        // Markdown content with proper padding and reference handling
        Padding(
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(
            data: controller.parsedAnswer.isNotEmpty ? controller.parsedAnswer : controller.answer,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              strong: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              em: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
              code: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.primary,
                  ),
              codeblockPadding: const EdgeInsets.all(8),
              codeblockDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
              a: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                if (href.startsWith('#ref-')) {
                  // This is a reference to an item in the app
                  final itemId = href.substring(5); // Remove '#ref-' prefix
                  _handleReferenceClick(itemId, controller);
                } else {
                  // Regular URL, use the existing URL launcher
                  _launchURL(href);
                }
              }
            },
          ),
        ),
        
        // // If there are references, show a divider and references section
        // if (controller.references.isNotEmpty) ...[
        //   Divider(
        //     color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        //     height: 1,
        //   ),
        //   Padding(
        //     padding: const EdgeInsets.all(16),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text(
        //           'Referenced Items:',
        //           style: Theme.of(context).textTheme.titleSmall?.copyWith(
        //                 fontWeight: FontWeight.bold,
        //                 color: Theme.of(context).colorScheme.onSurface,
        //               ),
        //         ),
        //         const SizedBox(height: 8),
        //         Wrap(
        //           spacing: 8,
        //           runSpacing: 8,
        //           children: controller.references.map((ref) {
        //             return _buildReferenceChip(ref, controller);
        //           }).toList(),
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
      ],
    ),
  );
}

// Add this method to handle reference clicks
void _handleReferenceClick(String itemId, HomeController controller) {
  try {
    final item = controller.findItemById(itemId);
    if (item != null) {
      if (item is NoteModel) {
        _handleNoteItemTap(note: item);
      } else if (item is PasswordModel) {
        authenticateUser(controller).then((_) {
          if (_isUserAuthorized) {
            _showPasswordBottomSheet(passwordNote: item);
          }
        });
      } else if (item is EventModel) {
        _showEventBottomSheet(context, eventNote: item);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referenced item not found'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error accessing referenced item: ${e.toString()}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Add this method to build reference chips
Widget _buildReferenceChip(ItemReference ref, HomeController controller) {
  late IconData icon;
  late Color color;
  
  switch (ref.type) {
    case ReferenceType.note:
      icon = Icons.note_outlined;
      color = Theme.of(context).colorScheme.primary;
      break;
    case ReferenceType.password:
      icon = Icons.lock_outlined;
      color = Theme.of(context).colorScheme.error;
      break;
    case ReferenceType.event:
      icon = Icons.event_outlined;
      color = Theme.of(context).colorScheme.tertiary;
      break;
  }

  return GestureDetector(
    onTap: () => _handleReferenceClick(ref.id, controller),
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: Icon(
          icon,
          size: 16,
          color: color,
        ),
        label: Text(ref.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: color.withOpacity(0.5),
        ),
      ),
    ),
  );
}
  // Add this method to handle URL launching
  Future<void> _launchURL(String? url) async {
    if (url != null) {
      final Uri uri = Uri.parse(url);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          // Show error if URL can't be launched
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $url'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        // Show error on exception
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
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
    );
  }

  Widget _buildQuestionInput(HomeController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: questionController,
            decoration: InputDecoration(
              hintText: '🤖 Ask your second brain...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => handleAsk(context),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.tertiary,
                Theme.of(context).colorScheme.primary
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => handleAsk(context),
            icon: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _handleAddOption(AddOption option) {
    switch (option) {
      case AddOption.note:
        _handleNoteItemTap();
        break;
      case AddOption.password:
        _showPasswordBottomSheet();
        break;

      case AddOption.event:
        _showEventBottomSheet(context);
        break;
    }
  }

  void _showPasswordBottomSheet({PasswordModel? passwordNote}) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: AddNoteScreen(
          note: passwordNote,
          isPasswordNote: true,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        context.read<HomeController>().loadNotes();
      }
    });
  }

  void _showAddOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AddOption.values
              .map((option) => ListTile(
                    leading: Icon(
                      option.icon,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(
                      option.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleAddOption(
                        option,
                      );
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> handleAsk(BuildContext context) async {
    final trimmedQuestion = questionController.text.trim();
    if (trimmedQuestion.isEmpty || context.read<HomeController>().isLoading)
      return;

    context.read<HomeController>().handleAsk(trimmedQuestion, context);
  }

  void _navigateToPasswordList(
      BuildContext context, HomeController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemListScreen(
          title: 'Passwords',
          items: controller.passwordsList,
          onItemTap: (note) {
            if (note is PasswordModel) {
              _showPasswordBottomSheet(passwordNote: note);
            }
          },
        ),
      ),
    );
  }

  void _handleNoteItemTap({NoteModel? note}) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: AddNoteScreen(
          note: note,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        context.read<HomeController>().loadNotes();
      }
    });
  }

  void _showEventBottomSheet(BuildContext context, {EventModel? eventNote}) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddEventWidget(
          eventNote: eventNote,
        ),
      ),
    ).then((eventData) {
      if (eventData != null) {
        // Handle delete action
        if (eventData['delete'] == true && eventData['id'] != null) {
          context
              .read<HomeController>()
              .deleteItem(eventData['id'])
              .then((_) => context.read<HomeController>().loadNotes());
          return;
        }

        // Handle create/update action
        final now = DateTime.now();
        final event = EventModel(
          id: eventData['id'] ?? now.millisecondsSinceEpoch.toString(),
          title: eventData['title'],
          description: eventData['description'] ?? '',
          eventDateTime: DateTime.parse(eventData['datetime']),
          createdAt: eventNote?.createdAt ?? DateTime.now(),
          updatedAt: now,
        );

        if (eventData['id'] != null) {
          context
              .read<HomeController>()
              .updateItem(event)
              .then((_) => context.read<HomeController>().loadNotes());
        } else {
          context
              .read<HomeController>()
              .addItem(event)
              .then((_) => context.read<HomeController>().loadNotes());
        }
      }
    });
  }
}
