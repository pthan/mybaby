import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/policy_screen.dart';
import 'presentation/screens/setting_screen.dart';
import 'presentation/screens/today_summary_screen.dart';
import 'presentation/screens/water_screen.dart';
import 'services/reminder_service.dart';
import 'theme/palette.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reminderService = ReminderService();
  await reminderService.init();
  runApp(
    ProviderScope(
      overrides: [
        reminderServiceProvider.overrideWithValue(reminderService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingControllerProvider);
    final mode = settings.themeMode();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyBaby Summary',
      themeMode: mode,
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppPalette.primary,
          onPrimary: AppPalette.textPrimary,
          secondary: AppPalette.secondary,
          onSecondary: AppPalette.textPrimary,
          surface: AppPalette.card,
          onSurface: AppPalette.textPrimary,
          background: AppPalette.background,
          onBackground: AppPalette.textPrimary,
          error: AppPalette.warning,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppPalette.background,
        cardColor: AppPalette.card,
        dividerColor: AppPalette.border,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppPalette.card,
          selectedItemColor: AppPalette.textPrimary,
          unselectedItemColor: AppPalette.textSecondary,
          selectedIconTheme: const IconThemeData(color: AppPalette.textPrimary),
          unselectedIconTheme: const IconThemeData(color: AppPalette.textSecondary),
          type: BottomNavigationBarType.fixed,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: AppPalette.primaryDark,
          onPrimary: Colors.black,
          secondary: AppPalette.secondary,
          onSecondary: Colors.black,
          surface: AppPalette.darkSurface,
          onSurface: Colors.white,
          background: AppPalette.darkBackground,
          onBackground: Colors.white,
          error: AppPalette.warning,
          onError: Colors.black,
        ),
        scaffoldBackgroundColor: AppPalette.darkBackground,
        cardColor: AppPalette.darkSurface,
        dividerColor: AppPalette.darkBorder,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppPalette.darkSurface,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedIconTheme: IconThemeData(color: Colors.white),
          unselectedIconTheme: IconThemeData(color: Colors.white70),
          type: BottomNavigationBarType.fixed,
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [
      TodaySummaryScreen(),
      WaterScreen(),
      PolicyScreen(),
      SettingScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop_outlined), label: 'Water'),
          BottomNavigationBarItem(icon: Icon(Icons.rule_folder_outlined), label: 'Policy'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
