import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/app_messages.dart';

class EmptySegmentsView extends StatelessWidget {
  const EmptySegmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppMessages.noSegmentsAvailable));
  }
}

class EmptyLocalSegmentsView extends StatelessWidget {
  const EmptyLocalSegmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppMessages.noLocalSegmentsSaved));
  }
}
