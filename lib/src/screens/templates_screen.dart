import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../api/templates_api.dart';
import '../config.dart';
import 'template_editor_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({
    super.key,
    required this.accessToken,
  });

  final String accessToken;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _api = TemplatesApi();
  final _meApi = ApiClient();
  bool _busy = true;
  String? _error;
  TemplatesListResponse? _list;
  String? _username;

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
      final results = await Future.wait([
        _api.listTemplates(accessToken: widget.accessToken),
        _meApi.me(accessToken: widget.accessToken),
      ]);
      final list = results[0] as TemplatesListResponse;
      final me = results[1] as MeResponse;
      if (!mounted) return;
      setState(() {
        _list = list;
        _username = me.username.trim().isEmpty ? null : me.username.trim();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _templateUrl({required String username, required TemplateListItem t}) {
    final base = AppConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/*$'), '');

    final published = t.versions.where((v) => v.isPublished).toList(growable: false);
    if (published.isEmpty) return null;

    final picked = published.first;
    final version = picked.version.trim();
    if (version.isEmpty) return null;

    final u = Uri.encodeComponent(username);
    final name = Uri.encodeComponent(t.name);
    final ver = Uri.encodeComponent(version);
    return '$base/$u/template/$name/$ver';
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied.')),
    );
  }

  Future<void> _createTemplate() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New template'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _api.createTemplate(accessToken: widget.accessToken, name: name);
      await _load();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = _list?.templates ?? const [];
    final username = _username;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _busy ? null : _createTemplate,
            icon: const Icon(Icons.add),
            tooltip: 'New template',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                Expanded(
                  child: templates.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No templates yet.'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _busy ? null : _createTemplate,
                                icon: const Icon(Icons.add),
                                label: const Text('Create your first template'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: templates.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final t = templates[index];
                            final version = (t.versions.isNotEmpty) ? t.versions.first.version : '1';
                            final obsUrl = (username == null) ? null : _templateUrl(username: username, t: t);
                            return ListTile(
                              title: Text(t.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Updated: ${t.updatedAt}'),
                                  if (obsUrl != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'OBS URL: $obsUrl',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              isThreeLine: obsUrl != null,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('v$version'),
                                  if (obsUrl != null)
                                    IconButton(
                                      tooltip: 'Copy OBS URL',
                                      icon: const Icon(Icons.copy, size: 18),
                                      onPressed: _busy ? null : () => _copy(obsUrl),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TemplateEditorScreen(
                                      accessToken: widget.accessToken,
                                      templateId: t.id,
                                      version: version,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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
