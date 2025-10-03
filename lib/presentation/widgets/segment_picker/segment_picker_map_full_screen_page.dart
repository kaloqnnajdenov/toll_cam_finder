import 'package:flutter/material.dart';

class SegmentPickerMapFullScreenPage extends StatelessWidget {
  const SegmentPickerMapFullScreenPage({
    super.key,
    required this.mapBuilder,
  });

  final WidgetBuilder mapBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Builder(builder: mapBuilder),
      ),
    );
  }
}
