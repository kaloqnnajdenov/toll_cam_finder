import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toll_cam_finder/presentation/pages/create_segment/widgets/segment_labeled_text_field.dart';

void main() {
  group('SegmentLabeledTextField allowedCharactersPattern', () {
    final formatter = FilteringTextInputFormatter.allow(
      SegmentLabeledTextField.allowedCharactersPattern,
    );

    test('retains Cyrillic input', () {
      const value = TextEditingValue(text: 'Улица Шипка');
      final result = formatter.formatEditUpdate(TextEditingValue.empty, value);

      expect(result.text, value.text);
    });

    test('removes unsupported control characters', () {
      const value = TextEditingValue(text: 'Road 1\nSecond line\t');
      final result = formatter.formatEditUpdate(TextEditingValue.empty, value);

      expect(result.text, 'Road 1Second line');
    });
  });
}
