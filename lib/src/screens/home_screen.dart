import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../widgets/cyber/cyber_background.dart';
import 'ai_alerts_screen.dart';
import 'features_settings_screen.dart';
import 'settings_screen.dart';
import 'templates_screen.dart';
import 'twitch_lookup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.api,
    required this.accessToken,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.accentName,
    required this.onAccentChanged,
  });

  final ApiClient api;
  final String accessToken;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String accentName;
  final ValueChanged<String> onAccentChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = true;
  String? _error;
  MeResponse? _me;

  bool _twitchBusy = false;
  String? _twitchError;
  TwitchUser? _twitchUser;
  bool? _twitchIsLive;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.health();
      final me = await widget.api.me(accessToken: widget.accessToken);
      if (!mounted) return;
      setState(() => _me = me);
      await _loadTwitchSummary(me);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadTwitchSummary(MeResponse me) async {
    final login = (me.twitchChannel ?? '').trim();
    if (login.isEmpty) {
      if (!mounted) return;
      setState(() {
        _twitchBusy = false;
        _twitchError = null;
        _twitchUser = null;
        _twitchIsLive = null;
      });
      return;
    }

    setState(() {
      _twitchBusy = true;
      _twitchError = null;
      _twitchUser = null;
      _twitchIsLive = null;
    });

    try {
      final users = await widget.api.twitchUsers(
        accessToken: widget.accessToken,
        login: login,
      );
      final user = users.isNotEmpty ? users.first : null;

      bool? isLive;
      try {
        final statuses = await widget.api.channelStatus(accessToken: widget.accessToken);
        final match = statuses.firstWhere(
          (s) => s.login.toLowerCase() == login.toLowerCase(),
          orElse: () => ChannelStatus(login: '', isLive: false),
        );
        if (match.login.isNotEmpty) {
          isLive = match.isLive;
        }
      } catch (_) {
        // Ignore status failures (often missing app credentials).
      }

      if (!mounted) return;
      setState(() {
        _twitchUser = user;
        _twitchIsLive = isLive;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _twitchError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _twitchError = e.toString());
    } finally {
      if (mounted) setState(() => _twitchBusy = false);
    }
  }

  Widget _twitchSummaryCard() {
    final me = _me;
    final login = (me?.twitchChannel ?? '').trim();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.18),
                  foregroundColor: scheme.onSurface,
                  backgroundImage: (_twitchUser?.profileImageUrl ?? '').trim().isEmpty
                      ? null
                      : NetworkImage(_twitchUser!.profileImageUrl),
                  child: (_twitchUser?.profileImageUrl ?? '').trim().isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Twitch channel',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        login.isEmpty ? 'Not set' : '@$login',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (_twitchBusy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            if (login.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Set your Twitch username in Settings to show your channel on the home page.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else if (_twitchError != null) ...[
              const SizedBox(height: 8),
              Text(
                _twitchError!,
                style: TextStyle(color: scheme.error),
              ),
            ] else ...[
              const SizedBox(height: 8),
              if (_twitchUser != null)
                Text(
                  _twitchUser!.displayName.isNotEmpty
                      ? _twitchUser!.displayName
                      : _twitchUser!.login,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (_twitchIsLive != null)
                Text(
                  _twitchIsLive == true ? 'Live now' : 'Offline',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pushCyber(Widget page) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  Widget _dashTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.22),
          ),
          gradient: LinearGradient(
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: 0.75),
              scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primary.withValues(alpha: 0.18),
              foregroundColor: scheme.onSurface,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      child: const Icon(Icons.videogame_asset_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TwitchDesk',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            me?.username.isNotEmpty == true
                                ? '@${me!.username}'
                                : 'Streamer tools',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Features Settings'),
                onTap: _busy
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _pushCyber(
                          FeaturesSettingsScreen(
                            api: widget.api,
                            accessToken: widget.accessToken,
                          ),
                        );
                        if (!mounted) return;
                        await _load();
                      },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Twitch Lookup'),
                onTap: _busy
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _pushCyber(
                          TwitchLookupScreen(
                            api: widget.api,
                            accessToken: widget.accessToken,
                          ),
                        );
                      },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_customize),
                title: const Text('Templates'),
                onTap: _busy
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _pushCyber(
                          TemplatesScreen(accessToken: widget.accessToken),
                        );
                      },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('AI Alerts'),
                onTap: _busy
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _pushCyber(
                          AiAlertsScreen(
                            api: widget.api,
                            accessToken: widget.accessToken,
                          ),
                        );
                      },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: _busy
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await _pushCyber(
                          SettingsScreen(
                            api: widget.api,
                            accessToken: widget.accessToken,
                            themeMode: widget.themeMode,
                            onThemeModeChanged: widget.onThemeModeChanged,
                            accentName: widget.accentName,
                            onAccentChanged: widget.onAccentChanged,
                          ),
                        );
                        if (!mounted) return;
                        await _load();
                      },
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.more_horiz),
                title: Text('More views coming later…'),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('TwitchDesk'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _busy ? null : widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: CyberBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Hero(
                      tag: 'td_logo',
                      child: CircleAvatar(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        child: const Icon(Icons.videogame_asset_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me?.username.isNotEmpty == true
                                ? 'Welcome, @${me!.username}'
                                : 'Welcome',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Streamer control center',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _twitchSummaryCard(),
                const SizedBox(height: 12),
                _dashTile(
                  icon: Icons.dashboard_customize,
                  title: 'Templates',
                  subtitle: 'Build alerts & overlays for OBS',
                  onTap: _busy
                      ? null
                      : () => _pushCyber(
                            TemplatesScreen(accessToken: widget.accessToken),
                          ),
                ),
                const SizedBox(height: 12),
                _dashTile(
                  icon: Icons.search,
                  title: 'Twitch Lookup',
                  subtitle: 'Quick search users & profiles',
                  onTap: _busy
                      ? null
                      : () => _pushCyber(
                            TwitchLookupScreen(
                              api: widget.api,
                              accessToken: widget.accessToken,
                            ),
                          ),
                ),
                const SizedBox(height: 12),
                _dashTile(
                  icon: Icons.tune,
                  title: 'Features',
                  subtitle: 'Public endpoints & streamer toggles',
                  onTap: _busy
                      ? null
                      : () async {
                          await _pushCyber(
                            FeaturesSettingsScreen(
                              api: widget.api,
                              accessToken: widget.accessToken,
                            ),
                          );
                          if (!mounted) return;
                          await _load();
                        },
                ),
                const SizedBox(height: 12),
                _dashTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Theme, accent, OAuth',
                  onTap: _busy
                      ? null
                      : () async {
                          await _pushCyber(
                            SettingsScreen(
                              api: widget.api,
                              accessToken: widget.accessToken,
                              themeMode: widget.themeMode,
                              onThemeModeChanged: widget.onThemeModeChanged,
                              accentName: widget.accentName,
                              onAccentChanged: widget.onAccentChanged,
                            ),
                          );
                          if (!mounted) return;
                          await _load();
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
