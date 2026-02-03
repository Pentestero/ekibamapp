import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart'; // ADD THIS IMPORT
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/theme.dart';
import 'package:provisions/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('fr_FR', null); // ADD THIS CALL

  await Supabase.initialize(
    url: 'https://ajparjbrzvaxfpafjbad.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqcGFyamJyenZheGZwYWZqYmFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyMTM0OTAsImV4cCI6MjA3NTc4OTQ5MH0.A3UNx_1z6EWBE3qwdQIXPth_iUyiuTXLKgl5m-wrDds',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthService.instance),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
      ],
      child: Builder(
        builder: (context) {
          final theme = context.watch<ThemeController>();
          return MaterialApp(
        title: 'EKIBAM',
        debugShowCheckedModeBanner: false,
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.mode,
        home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
