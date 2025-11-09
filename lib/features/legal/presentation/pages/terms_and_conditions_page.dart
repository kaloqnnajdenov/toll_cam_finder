import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/legal/presentation/widgets/terms_sections.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final sections = buildTermsSections(localizations);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.termsAndConditions),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            return TermsSectionWidget(section: sections[index]);
          },
        ),
      ),
    );
  }
}
