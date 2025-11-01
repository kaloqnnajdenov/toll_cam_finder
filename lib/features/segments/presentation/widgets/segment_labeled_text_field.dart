import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SegmentLabeledTextField extends StatelessWidget {
  const SegmentLabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.focusNode,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;

  @visibleForTesting
  static final RegExp allowedCharactersPattern = RegExp(
    r'[\p{L}\p{M}\p{N}\p{P}\p{S}\p{Zs}]',
    unicode: true,
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: [
        FilteringTextInputFormatter.allow(allowedCharactersPattern),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
