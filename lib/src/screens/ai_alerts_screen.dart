import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';

class AiAlertsScreen extends StatefulWidget {
  const AiAlertsScreen({
    super.key,
    required this.api,
    required this.accessToken,
  });

  final ApiClient api;
  final String accessToken;

  @override
  State<AiAlertsScreen> createState() => _AiAlertsScreenState();
}

class _AiAlertsScreenState extends State<AiAlertsScreen> {
  final _tokenCtrl = TextEditingController();

  bool _busy = true;
  String? _error;

  String? _username;
  AiTokenStatusResponse? _tokenStatus;
  AiAlertsListResponse? _alerts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.api.me(accessToken: widget.accessToken),
        widget.api.aiTokenStatus(accessToken: widget.accessToken),
        widget.api.aiAlertsList(accessToken: widget.accessToken),
      ]);

      final me = results[0] as MeResponse;
      final token = results[1] as AiTokenStatusResponse;
      final alerts = results[2] as AiAlertsListResponse;

      if (!mounted) return;
      setState(() {
        _username = me.username.trim().isEmpty ? null : me.username.trim();
        _tokenStatus = token;
        _alerts = alerts;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied.')),
    );
  }

  Future<void> _saveToken() async {
    final tok = _tokenCtrl.text.trim();
    if (tok.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.aiTokenPut(accessToken: widget.accessToken, token: tok);
      _tokenCtrl.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token saved.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnectToken() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.aiTokenDelete(accessToken: widget.accessToken);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createAlert() async {
    final nameCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    var enabled = true;
    final cooldownCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New AI alert'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prompt',
                    hintText: 'Use {{username}} and {{message}}',
                  ),
                  minLines: 3,
                  maxLines: 10,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: enabled,
                  onChanged: (v) => enabled = v,
                  title: const Text('Enabled'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cooldownCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cooldown (ms)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    final prompt = promptCtrl.text.trim();
    final cooldownMs = int.tryParse(cooldownCtrl.text.trim()) ?? 0;
    if (name.isEmpty || prompt.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.aiAlertsCreate(
        accessToken: widget.accessToken,
        name: name,
        prompt: prompt,
        isEnabled: enabled,
        cooldownMs: cooldownMs,
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

  String? _withUsername(String? url) {
    final u = _username;
    if (url == null || url.trim().isEmpty) return null;
    if (u == null || u.isEmpty) return url;
    return url.replaceAll('{username}', Uri.encodeComponent(u));
  }

  Future<void> _openAlertEditor(AiAlertListItem item) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    AiAlertDetailResponse? detail;
    AiAlertPublicStatusResponse? pub;

    try {
      final results = await Future.wait([
        widget.api.aiAlertsGet(accessToken: widget.accessToken, alertId: item.id),
        widget.api.aiAlertPublicStatus(accessToken: widget.accessToken, alertId: item.id),
      ]);
      detail = results[0] as AiAlertDetailResponse;
      pub = results[1] as AiAlertPublicStatusResponse;
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted || detail == null || pub == null) return;

    final nameCtrl = TextEditingController(text: detail.name);
    final promptCtrl = TextEditingController(text: detail.prompt);
    final cooldownCtrl = TextEditingController(text: detail.cooldownMs.toString());
    var enabled = detail.isEnabled;

    final testEventIdCtrl = TextEditingController(text: 'test-${DateTime.now().millisecondsSinceEpoch}');
    final testUsernameCtrl = TextEditingController(text: _username ?? '');
    final testMessageCtrl = TextEditingController(text: 'Hello from TwitchDesk');

    AiAlertPublicStatusResponse currentPub = pub;
    AiAlertFireResponse? lastFire;
    String? localError;

    Future<void> refreshPublic(StateSetter setInner) async {
      try {
        final s = await widget.api.aiAlertPublicStatus(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        setInner(() => currentPub = s);
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> enablePublic(StateSetter setInner) async {
      try {
        final s = await widget.api.aiAlertPublicEnable(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        setInner(() {
          currentPub = s;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> disablePublic(StateSetter setInner) async {
      try {
        await widget.api.aiAlertPublicDisable(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        await refreshPublic(setInner);
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> testFire(StateSetter setInner) async {
      final raw = currentPub.publicUrl;
      final url = _withUsername(raw);
      final eventId = testEventIdCtrl.text.trim();
      if (url == null || url.isEmpty) {
        setInner(() => localError = 'Public URL not available (check PUBLIC_BASE_URL + enable).');
        return;
      }
      if (eventId.isEmpty) {
        setInner(() => localError = 'Missing event_id');
        return;
      }

      try {
        final res = await widget.api.aiAlertFire(
          publicUrl: url,
          eventId: eventId,
          username: testUsernameCtrl.text.trim().isEmpty ? null : testUsernameCtrl.text.trim(),
          message: testMessageCtrl.text.trim().isEmpty ? null : testMessageCtrl.text.trim(),
        );
        setInner(() {
          lastFire = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    final res = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) {
          final canCopy = _withUsername(currentPub.publicUrl);

          return AlertDialog(
            title: Text('Edit: ${detail!.name}'),
            content: SizedBox(
              width: 720,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (localError != null) ...[
                      Text(
                        localError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: promptCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prompt',
                        hintText: 'Use {{username}} and {{message}}',
                      ),
                      minLines: 3,
                      maxLines: 10,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: enabled,
                      onChanged: (v) => setInner(() => enabled = v),
                      title: const Text('Enabled'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cooldownCtrl,
                      decoration: const InputDecoration(labelText: 'Cooldown (ms)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Public overlay URL',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (currentPub.enabled)
                          OutlinedButton(
                            onPressed: () => disablePublic(setInner),
                            child: const Text('Disable'),
                          )
                        else
                          FilledButton.tonal(
                            onPressed: () => enablePublic(setInner),
                            child: const Text('Enable'),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () => refreshPublic(setInner),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentPub.publicUrl == null) ...[
                      Text(
                        currentPub.enabled
                            ? 'Enabled, but no URL was returned. Check server env: PUBLIC_BASE_URL.'
                            : 'Disabled.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      SelectableText(canCopy ?? currentPub.publicUrl!),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: canCopy == null ? null : () => _copy(canCopy),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Test fire',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: testEventIdCtrl,
                      decoration: const InputDecoration(labelText: 'event_id'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testUsernameCtrl,
                      decoration: const InputDecoration(labelText: 'username (optional)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testMessageCtrl,
                      decoration: const InputDecoration(labelText: 'message (optional)'),
                      minLines: 2,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => testFire(setInner),
                      child: const Text('Send test'),
                    ),
                    if (lastFire != null) ...[
                      const SizedBox(height: 12),
                      Text('Status: ${lastFire!.status}'),
                      if ((lastFire!.text ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(lastFire!.text!),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('delete'),
                child: const Text('Delete'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop('save'),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (res == null) return;

    if (res == 'delete') {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        await widget.api.aiAlertsDelete(accessToken: widget.accessToken, alertId: item.id);
        await _load();
      } on ApiException catch (e) {
        setState(() => _error = e.message);
      } catch (e) {
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    if (res == 'save') {
      final name = nameCtrl.text.trim();
      final prompt = promptCtrl.text.trim();
      final cooldownMs = int.tryParse(cooldownCtrl.text.trim()) ?? 0;
      if (name.isEmpty || prompt.isEmpty) return;

      setState(() {
        _busy = true;
        _error = null;
      });

      try {
        await widget.api.aiAlertsUpdate(
          accessToken: widget.accessToken,
          alertId: item.id,
          name: name,
          prompt: prompt,
          isEnabled: enabled,
          cooldownMs: cooldownMs,
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
  }

  @override
  Widget build(BuildContext context) {
    final connected = _tokenStatus?.connected;
    final alerts = _alerts?.alerts ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Alerts'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
          IconButton(
            onPressed: _busy ? null : _createAlert,
            icon: const Icon(Icons.add),
            tooltip: 'New alert',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
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
                          'OpenAI token',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          connected == null
                              ? 'Loading…'
                              : (connected ? 'Connected' : 'Not connected'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _tokenCtrl,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Paste token to connect',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _busy ? null : _saveToken,
                                child: const Text('Save token'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: (_busy || connected != true) ? null : _disconnectToken,
                                child: const Text('Disconnect'),
                              ),
                            ),
                          ],
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
                        Text(
                          'Alerts',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (alerts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                const Text('No AI alerts yet.'),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _busy ? null : _createAlert,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create your first alert'),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: alerts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final a = alerts[index];
                              return ListTile(
                                title: Text(a.name),
                                subtitle: Text(
                                  'Updated: ${a.updatedAt} • Cooldown: ${a.cooldownMs}ms',
                                ),
                                trailing: a.isEnabled
                                    ? const Icon(Icons.check_circle_outline)
                                    : const Icon(Icons.pause_circle_outline),
                                onTap: _busy ? null : () => _openAlertEditor(a),
                              );
                            },
                          ),
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
