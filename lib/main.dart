import 'package:flutter/material.dart';

import 'src/api/api_client.dart';
import 'src/auth/auth_store.dart';
import 'src/settings/theme_store.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/login_screen.dart';

void main() {
  runApp(const TwitchDeskApp());
}

class TwitchDeskApp extends StatefulWidget {
  const TwitchDeskApp({super.key});

  @override
  State<TwitchDeskApp> createState() => _TwitchDeskAppState();
}

class _TwitchDeskAppState extends State<TwitchDeskApp> {
  final _api = ApiClient();
  final _authStore = AuthStore();
  final _themeStore = ThemeStore();
  final _navigatorKey = GlobalKey<NavigatorState>();

  String? _accessToken;
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentSeed = Colors.deepPurple;
  String _accentName = 'Purple';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _authStore.loadAccessToken(),
      _themeStore.loadThemeMode(),
      _themeStore.loadAccentSeedColor(),
      _themeStore.loadAccentName(),
    ]);

    final tok = results[0] as String?;
    final themeMode = results[1] as ThemeMode;
    final accentSeed = results[2] as Color;
    final accentName = results[3] as String;
    if (!mounted) return;
    setState(() {
      _accessToken = tok;
      _themeMode = themeMode;
      _accentSeed = accentSeed;
      _accentName = accentName;
      _loaded = true;
    });

    if (_accessToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLogin());
    }
  }

  Future<void> _showLogin() async {
    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    final res = await nav.push<LoginResult>(
      MaterialPageRoute(builder: (_) => LoginScreen(api: _api)),
    );
    if (res == null) return;

    await _authStore.saveAccessToken(res.accessToken);
    if (!mounted) return;
    setState(() => _accessToken = res.accessToken);
  }

  Future<void> _logout() async {
    await _authStore.clear();
    if (!mounted) return;
    setState(() => _accessToken = null);
    await _showLogin();
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await _themeStore.saveThemeMode(mode);
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  Future<void> _setAccentName(String name) async {
    await _themeStore.saveAccentName(name);
    final color = await _themeStore.loadAccentSeedColor();
    if (!mounted) return;
    setState(() {
      _accentSeed = color;
      _accentName = name;
    });
  }

  ThemeData _buildTheme(Brightness brightness, Color seedColor) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: rounded,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        shape: rounded,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(0, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(0, 44),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tok = _accessToken;

    return MaterialApp(
      title: 'TwitchDesk',
      navigatorKey: _navigatorKey,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light, _accentSeed),
      darkTheme: _buildTheme(Brightness.dark, _accentSeed),
      home: !_loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (tok == null
              ? Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: _showLogin,
                      child: const Text('Log in'),
                    ),
                  ),
                )
              : HomeScreen(
                  api: _api,
                  accessToken: tok,
                  onLogout: _logout,
                  themeMode: _themeMode,
                  onThemeModeChanged: _setThemeMode,
                  accentName: _accentName,
                  onAccentChanged: _setAccentName,
                )),
    );
  }
}
