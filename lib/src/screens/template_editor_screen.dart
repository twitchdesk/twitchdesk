import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/templates_api.dart';
import '../widgets/live_preview/live_preview.dart';

class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({
    super.key,
    required this.accessToken,
    required this.templateId,
    required this.version,
  });

  final String accessToken;
  final String templateId;
  final String version;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen>
    with SingleTickerProviderStateMixin {
  final _api = TemplatesApi();

  late final TabController _tab;

  final _htmlCtrl = TextEditingController();
  final _cssCtrl = TextEditingController();
  final _jsCtrl = TextEditingController();

  Timer? _previewDebounce;

  bool _busy = true;
  String? _error;

  bool _isPublished = false;

  String _previewHtml = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();

    _htmlCtrl.addListener(_schedulePreviewUpdate);
    _cssCtrl.addListener(_schedulePreviewUpdate);
    _jsCtrl.addListener(_schedulePreviewUpdate);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _tab.dispose();
    _htmlCtrl.dispose();
    _cssCtrl.dispose();
    _jsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final v = await _api.getVersion(
        accessToken: widget.accessToken,
        templateId: widget.templateId,
        version: widget.version,
      );
      if (!mounted) return;

      _htmlCtrl.text = v.indexHtml;
      _cssCtrl.text = v.styleCss;
      _jsCtrl.text = v.overlayJs;
      setState(() => _isPublished = v.isPublished);
      _updatePreviewNow();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _assembleHtml(String indexHtml, String styleCss, String overlayJs) {
    return '''<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
$styleCss
    </style>
  </head>
  <body>
$indexHtml
    <script>
$overlayJs
    </script>
  </body>
</html>''';
  }

  void _schedulePreviewUpdate() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 200), _updatePreviewNow);
  }

  void _updatePreviewNow() {
    final html = _assembleHtml(_htmlCtrl.text, _cssCtrl.text, _jsCtrl.text);
    setState(() => _previewHtml = html);
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _api.updateVersion(
        accessToken: widget.accessToken,
        templateId: widget.templateId,
        version: widget.version,
        indexHtml: _htmlCtrl.text,
        styleCss: _cssCtrl.text,
        overlayJs: _jsCtrl.text,
      );
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

  Future<void> _publish() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final v = await _api.publishVersion(
        accessToken: widget.accessToken,
        templateId: widget.templateId,
        version: widget.version,
      );
      if (!mounted) return;
      setState(() => _isPublished = v.isPublished);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Published.')),
      );
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
    final wide = MediaQuery.of(context).size.width >= 1000;

    Widget editorPane() {
      return Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'HTML'),
              Tab(text: 'CSS'),
              Tab(text: 'JS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _codeField(_htmlCtrl),
                _codeField(_cssCtrl),
                _codeField(_jsCtrl),
              ],
            ),
          ),
        ],
      );
    }

    final previewPane = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: LivePreview(html: _previewHtml),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Template v${widget.version}'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: (_busy || _isPublished) ? null : _publish,
            child: const Text('Publish'),
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: wide
                  ? Row(
                      children: [
                        Expanded(child: editorPane()),
                        const SizedBox(width: 12),
                        Expanded(child: previewPane),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: editorPane()),
                        const SizedBox(height: 12),
                        SizedBox(height: 300, child: previewPane),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeField(TextEditingController controller) {
    return TextField(
      controller: controller,
      expands: true,
      maxLines: null,
      minLines: null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      textAlignVertical: TextAlignVertical.top,
    );
  }
}
