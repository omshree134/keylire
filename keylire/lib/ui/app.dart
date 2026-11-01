import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';

import 'controllers/app_state.dart';
import '../services/backup/backup_file_bridge.dart';
import 'screens/how_to_use_screen.dart';
import 'screens/lists_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/patterns_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'theme/daylog_theme.dart';
import 'widgets/undo_chip.dart';

class KeylireApp extends StatelessWidget {
  const KeylireApp({super.key, required this.services, this.onboarded});
  final Services services;
  final bool? onboarded;

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: MaterialApp(
        title: 'Keylire',
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

class _RootState extends State<_Root> with WidgetsBindingObserver {
  bool? _onboarded;
  bool? _showHowTo;
  bool _locked = false;
  int _tab = 0;
  int _dataRevision = 0;
  bool _handlingBackup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _onboarded = widget.onboarded;
    _showHowTo = widget.onboarded == null ? null : false;
    _checkLock();
    _checkOnboarding();
    _widgets();
    _backupFiles();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _checkLock(relock: true);
    }
  }

  Future<void> _checkLock({bool relock = false}) async {
    final hasPass = await widget.services.settings.hasPasscode();
    if (hasPass && mounted) {
      if (relock || !_locked) {
        setState(() => _locked = true);
      }
    }
  }

  Future<void> _backupFiles() async {
    BackupFileBridge.configure(_offerBackupRestore);
    final pending = await BackupFileBridge.takePendingImport();
    if (pending != null) await _offerBackupRestore(pending);
  }

  Future<void> _offerBackupRestore(String path) async {
    if (!mounted || _handlingBackup) return;
    _handlingBackup = true;
    final staged = File(path);
    try {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restore this Keylire backup?'),
          content: const Text(
            'This replaces the keys, logs, lists, patterns, and settings currently on this device. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;

      final controller = TextEditingController();
      final passphrase = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Backup passphrase'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter the passphrase used when exporting',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (passphrase == null || passphrase.isEmpty || !mounted) return;

      try {
        await widget.services.export.restoreEncrypted(staged, passphrase);
        await widget.services.db.putSetting('onboarded', 'true');
        await widget.services.settings.setHowToSeen(true);
        await widget.services.matcher.warmUp();
        if (!mounted) return;
        setState(() {
          _onboarded = true;
          _showHowTo = false;
          _tab = 0;
          _dataRevision++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keylire backup restored')),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Could not restore. Check the file and passphrase.'),
            ),
          );
        }
      }
    } finally {
      _handlingBackup = false;
      try {
        if (await staged.exists()) await staged.delete();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BackupFileBridge.configure(null);
    super.dispose();
  }

  Future<void> _widgets() async {
    try {
      HomeWidget.setAppGroupId('group.com.keylire.app');
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
    // keylire://open/text|mic|camera - iOS doors (and any launcher without
    // background support) land here with the door already open.
    final door = uri.host == 'open' ? uri.path.replaceFirst('/', '') : null;
    if (door != null) {
      Future.delayed(const Duration(milliseconds: 250),
          () => WidgetActionBus.dispatch('keylire://capture/$door'));
      return;
    }
    WidgetActionBus.dispatch(uri.toString());
  }

  Future<void> _checkOnboarding() async {
    if (widget.onboarded != null) return;
    final v = await widget.services.db.setting('onboarded');
    final seenGuide = await widget.services.settings.hasSeenHowTo();
    if (mounted) {
      setState(() {
        _onboarded = v == 'true';
        _showHowTo = v == 'true' && !seenGuide;
      });
    }
  }

  Future<void> _finishHowTo() async {
    await widget.services.settings.setHowToSeen(true);
    if (mounted) setState(() => _showHowTo = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return _PasscodeLockScreen(
        services: widget.services,
        onUnlocked: () => setState(() => _locked = false),
      );
    }
    if (_onboarded == null || _showHowTo == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (!_onboarded!) {
      return OnboardingScreen(
        onDone: () => setState(() {
          _onboarded = true;
          _showHowTo = true;
        }),
      );
    }
    if (_showHowTo!) {
      return HowToUseScreen(firstRun: true, onDone: _finishHowTo);
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          key: ValueKey(_dataRevision),
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
          NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.checklist_rtl),
              selectedIcon: Icon(Icons.checklist),
              label: 'Lists'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Patterns'),
          NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Settings'),
        ],
      ),
    );
  }
}

class _PasscodeLockScreen extends StatefulWidget {
  const _PasscodeLockScreen({required this.services, required this.onUnlocked});
  final Services services;
  final VoidCallback onUnlocked;

  @override
  State<_PasscodeLockScreen> createState() => _PasscodeLockScreenState();
}

class _PasscodeLockScreenState extends State<_PasscodeLockScreen> {
  String _pin = '';
  String? _error;

  void _digit(String d) async {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    final newPin = '$_pin$d';
    setState(() {
      _pin = newPin;
      _error = null;
    });

    if (newPin.length == 4) {
      final ok = await widget.services.settings.verifyPasscode(newPin);
      if (ok) {
        widget.onUnlocked();
      } else {
        HapticFeedback.mediumImpact();
        if (mounted) {
          setState(() {
            _pin = '';
            _error = 'Incorrect PIN';
          });
        }
      }
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dl = Dl.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dl.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Icon(Icons.lock_outline,
                  size: 40, color: theme.colorScheme.primary),
              SizedBox(height: dl.x3),
              Text('Keylire', style: theme.textTheme.displayMedium),
              SizedBox(height: dl.x1),
              Text(
                _error ?? 'Enter your 4-digit PIN',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: _error != null ? FontWeight.w600 : null,
                ),
              ),
              SizedBox(height: dl.x6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(flex: 2),
              for (var row = 0; row < 3; row++)
                Padding(
                  padding: EdgeInsets.only(bottom: dl.x4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var col = 1; col <= 3; col++)
                        _pinKey('${row * 3 + col}', theme),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(bottom: dl.x4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 72, height: 72),
                    _pinKey('0', theme),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 24),
                        onPressed: _pin.isNotEmpty ? _backspace : null,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinKey(String digit, ThemeData theme) {
    return SizedBox(
      width: 72,
      height: 72,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        onPressed: () => _digit(digit),
        child: Text(
          digit,
          style: DlType.mono(context, size: 24, weight: FontWeight.w500),
        ),
      ),
    );
  }
}
