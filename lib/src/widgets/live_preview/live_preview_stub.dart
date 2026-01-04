import 'package:flutter/material.dart';

class LivePreview extends StatelessWidget {
  const LivePreview({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Live preview is not supported on this platform yet.'),
    );
  }
}
