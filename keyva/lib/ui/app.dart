import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';

import 'controllers/app_state.dart';
import 'screens/lists_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/patterns_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'theme/daylog_theme.dart';
import 'widgets/undo_chip.dart';

class KeyvaApp extends StatelessWidget {
  const KeyvaApp({super.key, required this.services, this.onboarded});
  final Services services;
  final bool? onboarded;

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: MaterialApp(
        title: 'Keyva',
        debugShowCheckedModeBanner: false,
        theme: daylogTheme(Brightness.light),
        darkTheme: daylogTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.4)),
            child: child!,
          );
        },
        home: _Root(services: services, onboarded: onboarded),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.services, this.onboarded});
  final Services services;
  final bool? onboarded;
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool? _onboarded;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _onboarded = widget.onboarded;
    _checkOnboarding();
    _widgets();
  }

  Future<void> _widgets() async {
    try {
      HomeWidget.setAppGroupId('group.com.keyva.app');
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initial != null) _handle(initial);
      HomeWidget.widgetClicked.listen((u) {
        if (u != null) _handle(u);
      });
    } catch (_) {}
  }

  void _handle(Uri uri) {
    if (!mounted) return;
    if (uri.path.contains('lists')) {
      setState(() => _tab = 1);
      return;
    }
    if (_tab != 0) setState(() => _tab = 0);
    // keyva://open/text|mic|camera - iOS doors (and any launcher without
    // background support) land here with the door already open.
    final door = uri.host == 'open' ? uri.path.replaceFirst('/', '') : null;
    if (door != null) {
      Future.delayed(const Duration(milliseconds: 250), () => WidgetActionBus.dispatch('keyva://capture/$door'));
      return;
    }
    WidgetActionBus.dispatch(uri.toString());
  }

  Future<void> _checkOnboarding() async {
    if (widget.onboarded != null) return;
    final v = await widget.services.db.setting('onboarded');
    if (mounted) setState(() => _onboarded = v == 'true');
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (!_onboarded!) return OnboardingScreen(onDone: () => setState(() => _onboarded = true));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            const TodayScreen(),
            ListsScreen(isActive: _tab == 1),
            PatternsScreen(isActive: _tab == 2),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          dismissUndoChip();
          if (_tab != i) setState(() => _tab = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.checklist_rtl), selectedIcon: Icon(Icons.checklist), label: 'Lists'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Patterns'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}
