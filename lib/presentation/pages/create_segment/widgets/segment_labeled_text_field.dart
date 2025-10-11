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
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final FocusNode? focusNode;

  @visibleForTesting
  static const RegExp allowedCharactersPattern = RegExp(
    r'[\p{L}\p{M}\p{N}\p{P}\p{S}\p{Zs}]',
    unicode: true,
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      inputFormatters: const [
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
