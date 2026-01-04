import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../config.dart';

class FeaturesSettingsScreen extends StatefulWidget {
  const FeaturesSettingsScreen({
    super.key,
    required this.api,
    required this.accessToken,
  });

  final ApiClient api;
  final String accessToken;

  @override
  State<FeaturesSettingsScreen> createState() => _FeaturesSettingsScreenState();
}

class _FeaturesSettingsScreenState extends State<FeaturesSettingsScreen> {
  bool _busy = true;
  String? _error;

  MeResponse? _me;

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
      final me = await widget.api.me(accessToken: widget.accessToken);
      if (!mounted) return;
      setState(() => _me = me);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setPublicAvatarEnabled(bool enabled) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.patchMe(
        accessToken: widget.accessToken,
        publicTwitchAvatarEnabled: enabled,
      );
      await _load();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _avatarEndpointUrl(MeResponse me) {
    // Public endpoint: /:account/twitchavatar?username=<twitch_login>
    // We can’t know the target twitch username here, so we show a placeholder.
    final base = AppConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/*$'), '');
    return '$base/${me.username}/twitchavatar?username=TWITCH_USERNAME';
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Features Settings'),
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
                        Text(
                          'Public Twitch Avatar',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: me?.publicTwitchAvatarEnabled ?? false,
                          onChanged: (_busy || me == null) ? null : _setPublicAvatarEnabled,
                          title: const Text('Enable public Twitch avatar endpoint'),
                        ),
                        if (me?.publicTwitchAvatarEnabled == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Endpoint URL (replace TWITCH_USERNAME):',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(_avatarEndpointUrl(me!)),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _busy ? null : () => _copy(_avatarEndpointUrl(me)),
                            child: const Text('Copy URL'),
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
