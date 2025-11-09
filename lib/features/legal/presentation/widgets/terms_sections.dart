import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';

class TermsSectionData {
  const TermsSectionData({
    required this.title,
    required this.body,
    this.bullets = const <String>[],
  });

  final String title;
  final String body;
  final List<String> bullets;
}

List<TermsSectionData> buildTermsSections(AppLocalizations localizations) {
  return [
    TermsSectionData(
      title: localizations.termsAcceptanceHeading,
      body: localizations.termsAcceptanceBody,
    ),
    TermsSectionData(
      title: localizations.termsThirdPartyHeading,
      body: localizations.termsThirdPartyIntro,
      bullets: [
        localizations.termsThirdPartyOsm,
        localizations.termsThirdPartySupabase,
        localizations.termsThirdPartyOther,
      ],
    ),
    TermsSectionData(
      title: localizations.termsSpeedHeading,
      body: localizations.termsSpeedBody,
    ),
    TermsSectionData(
      title: localizations.termsUserResponsibilityHeading,
      body: localizations.termsUserResponsibilityBody,
    ),
    TermsSectionData(
      title: localizations.termsLiabilityHeading,
      body: localizations.termsLiabilityBody,
    ),
    TermsSectionData(
      title: localizations.termsChangesHeading,
      body: localizations.termsChangesBody,
    ),
    TermsSectionData(
      title: localizations.termsContactHeading,
      body: localizations.termsContactBody,
    ),
  ];
}

class TermsSectionWidget extends StatelessWidget {
  const TermsSectionWidget({super.key, required this.section});

  final TermsSectionData section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = theme.textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: titleStyle),
        const SizedBox(height: 8),
        Text(section.body, style: bodyStyle),
        if (section.bullets.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: section.bullets
                .map((bullet) => TermsBullet(text: bullet))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class TermsBullet extends StatelessWidget {
  const TermsBullet({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: bodyStyle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}
