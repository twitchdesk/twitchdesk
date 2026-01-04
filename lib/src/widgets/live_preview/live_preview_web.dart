// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

// Web implementation using an iframe with srcdoc.

import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

import 'dart:html' as html;

class LivePreview extends StatefulWidget {
  const LivePreview({super.key, required this.html});

  final String html;

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
  late final String _viewType;
  late final html.IFrameElement _iframe;

  @override
  void initState() {
    super.initState();

    _viewType = 'twitchdesk-live-preview-${DateTime.now().microsecondsSinceEpoch}';
    _iframe = html.IFrameElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..sandbox?.add('allow-scripts')
      ..sandbox?.add('allow-same-origin')
      ..srcdoc = widget.html;

    ui.platformViewRegistry.registerViewFactory(_viewType, (int _) => _iframe);
  }

  @override
  void didUpdateWidget(covariant LivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _iframe.srcdoc = widget.html;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
