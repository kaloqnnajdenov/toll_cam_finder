import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';

class EmptySegmentsView extends StatelessWidget {
  const EmptySegmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context).noSegmentsAvailable));
  }
}

class EmptyLocalSegmentsView extends StatelessWidget {
  const EmptyLocalSegmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context).noLocalSegments));
  }
}
