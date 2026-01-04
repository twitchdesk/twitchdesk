import 'dart:io';

import 'package:flutter/material.dart';

// Windows embedded preview.
import 'package:webview_windows/webview_windows.dart';

class LivePreview extends StatefulWidget {
  const LivePreview({super.key, required this.html});

  final String html;

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
  final _controller = WebviewController();
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!Platform.isWindows) {
      setState(() {
        _ready = false;
        _error = 'Live preview is only implemented for Web and Windows right now.';
      });
      return;
    }

    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.loadStringContent(widget.html);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _ready = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant LivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;
    if (oldWidget.html != widget.html) {
      // Fire-and-forget; the webview may not be ready during rapid typing.
      _controller.loadStringContent(widget.html);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return Webview(_controller);
  }
}
