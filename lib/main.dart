import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/usage_service.dart';
import 'providers/mood_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'constants/app_strings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UsageService()),
        ChangeNotifierProvider(create: (context) => MoodProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          themeMode: settings.darkModeEnabled
              ? ThemeMode.dark
              : ThemeMode.light,

          // --- LIGHT THEME ---
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter', // IMPORTANT: Must be in pubspec.yaml
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,

            // Color Scheme
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6200EE), // Purple
              brightness: Brightness.light,
              surface: Colors.white,
            ),

            // Flat AppBar with Border
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white, // Matches body
              foregroundColor: const Color(0xFF6200EE), // Purple Label
              elevation: 0,
              centerTitle: false,
              titleTextStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.bold, // Bold Label
                color: Color(0xFF6200EE),
              ),
              shape: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),

            // Material You Bottom Nav (Pill Style)
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFFF3F0FF), // Light Purple Tint
              indicatorColor: const Color(0xFFBB86FC).withValues(alpha: 0.3),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: Color(0xFF6200EE));
                }
                return const IconThemeData(color: Colors.grey);
              }),
            ),
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212), // Deep Dark
            // Color Scheme
            colorScheme:
                ColorScheme.fromSeed(
                  seedColor: const Color(0xFF64B5F6),
                  brightness: Brightness.dark,
                  surface: const Color(0xFF121212),
                ).copyWith(
                  // Explicitly force this color as primary to avoid pastel variations
                  primary: const Color(0xFF64B5F6),
                ),

            // Flat AppBar with Border
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF121212), // Matches body
              foregroundColor: const Color(0xFF64B5F6), // Cyan Label
              elevation: 0,
              centerTitle: false,
              titleTextStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64B5F6),
              ),
              shape: Border(
                bottom: BorderSide(color: Colors.grey.shade800, width: 1),
              ),
            ),

            // Material You Bottom Nav (Pill Style)
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(
                0xFF1E1E1E,
              ), // Slightly lighter than body
              indicatorColor: const Color(0xFF64B5F6).withValues(alpha: 0.2),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: Color(0xFF64B5F6));
                }
                return const IconThemeData(color: Colors.grey);
              }),
            ),
          ),

          home: const HomeScreen(),
        );
      },
    );
  }
}
