import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:linkage/screens/login_screen.dart';
import 'package:linkage/screens/prompt_screen/prompt_screen.dart';
import 'package:linkage/screens/table_screen/table_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  try {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'SUPABASE_URL',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'SUPABASE_ANON_KEY',
    );

    debugPrint('Supabase URL: ${dotenv.env['SUPABASE_URL']}');
    debugPrint('Supabase Anon Key: ${dotenv.env['SUPABASE_ANON_KEY']}');
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Supabase: $e');
    debugPrint('StackTrace: $stackTrace');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final supabase = Supabase.instance.client;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linkage',
      // theme: lightTheme,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
      ),
      // darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      initialRoute: supabase.auth.currentSession == null ? "/login" : "/home",
      routes: {
        '/home': (context) => const PromptScreen(),
        "/login": (context) => LoginScreen(),
      },
    );
  }
}
