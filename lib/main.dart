import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'controllers/home_controller.dart';
import 'utils/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  final homeController = HomeController();
  await homeController.initializeTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: homeController,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize theme
    final baseTextTheme =
        GoogleFonts.interTextTheme(Theme.of(context).textTheme);
    final materialTheme = MaterialTheme(baseTextTheme);

    return Consumer<HomeController>(
      builder: (context, controller, _) => MaterialApp(
        title: 'Second Brain',
        debugShowCheckedModeBanner: false,
        theme: materialTheme.light(),
        darkTheme: materialTheme.dark(),
        themeMode: controller.themeMode,
        home: const HomeScreen(),
      ),
    );
  }
}
