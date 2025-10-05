import 'package:flutter/material.dart';

class EmptySegmentsView extends StatelessWidget {
  const EmptySegmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No segments available.'));
  }
}

class EmptyLocalSegmentsView extends StatelessWidget {
  const EmptyLocalSegmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No local segments saved yet.'));
  }
}
