import 'package:flutter/material.dart';

class SegmentLabeledTextField extends StatelessWidget {
  const SegmentLabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
