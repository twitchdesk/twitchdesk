import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../settings/theme_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.api,
    required this.accessToken,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.accentName,
    required this.onAccentChanged,
  });

  final ApiClient api;
  final String accessToken;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String accentName;
  final ValueChanged<String> onAccentChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _clientIdCtrl = TextEditingController();
  final _clientSecretCtrl = TextEditingController();

  late ThemeMode _themeMode;
  late String _accentName;

  bool _busy = true;
  String? _error;

  MeResponse? _me;

  TwitchOAuthStartResponse? _oauthInfo;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _accentName = widget.accentName;
    _load();
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final me = await widget.api.me(accessToken: widget.accessToken);
      if (!mounted) return;

      _clientIdCtrl.text = me.twitchClientId;

      setState(() {
        _me = me;
        _oauthInfo = null;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.patchMe(
        accessToken: widget.accessToken,
        twitchClientId: _clientIdCtrl.text.trim(),
        twitchClientSecret: _clientSecretCtrl.text.trim().isEmpty
            ? null
            : _clientSecretCtrl.text.trim(),
      );

      _clientSecretCtrl.clear();
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fetchCallbackUrl() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final res = await widget.api.twitchOauthStart(accessToken: widget.accessToken);
      if (!mounted) return;
      setState(() => _oauthInfo = res);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyCallbackUrl() async {
    final url = _oauthInfo?.redirectUri.trim();
    if (url == null || url.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Callback URL copied.')),
    );
  }

  Future<void> _startOauth() async {
    final url = _oauthInfo?.url.trim();
    if (url == null || url.isEmpty) return;

    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      setState(() => _error = 'Could not open browser for Twitch OAuth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Appearance',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ThemeMode>(
                          initialValue: _themeMode,
                          decoration: const InputDecoration(
                            labelText: 'Theme',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                          ],
                          onChanged: _busy
                              ? null
                              : (mode) {
                                  if (mode == null) return;
                                  setState(() => _themeMode = mode);
                                  widget.onThemeModeChanged(mode);
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _accentName,
                          decoration: const InputDecoration(
                            labelText: 'Accent',
                            border: OutlineInputBorder(),
                          ),
                          items: ThemeStore.accentOptions()
                              .keys
                              .map(
                                (name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _busy
                              ? null
                              : (name) {
                                  if (name == null) return;
                                  setState(() => _accentName = name);
                                  widget.onAccentChanged(name);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Twitch App', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _clientIdCtrl,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Client ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _clientSecretCtrl,
                          enabled: !_busy,
                          decoration: InputDecoration(
                            labelText: 'Client Secret',
                            hintText: (me?.hasClientSecret == true)
                                ? 'Already set (leave empty to keep)'
                                : 'Required for Twitch API',
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _busy ? null : _save,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('OAuth Callback URL',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Use this URL as the Redirect URI in your Twitch app settings.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: _busy ? null : _fetchCallbackUrl,
                          child: const Text('Get callback URL'),
                        ),
                        if ((_oauthInfo?.redirectUri ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SelectableText(_oauthInfo!.redirectUri),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _busy ? null : _copyCallbackUrl,
                                  child: const Text('Copy'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _busy ? null : _startOauth,
                                  child: const Text('Start Twitch OAuth'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
