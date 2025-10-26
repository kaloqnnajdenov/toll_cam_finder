import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toll_cam_finder/app/app_routes.dart';
import 'package:toll_cam_finder/features/intro/application/intro_controller.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Toll Cam Finder',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Here\'s a quick tour to help you feel confident the first time you hit the road with the app.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: const [
                    _IntroHighlight(
                      title: 'Map tour: orienting controls and telemetry',
                      description:
                          'Keep the floating controls in mind—they let you lock the map to your driving direction or instantly snap back to your live position so you can regain context mid-trip.',
                    ),
                    _IntroHighlight(
                      title: 'Glanceable speed insights',
                      description:
                          'Use the translucent metrics card to monitor your current speed, rolling average, and safe speed guidance versus the posted limit. It also shows the distance to your active or nearest segment so compliance is always clear.',
                    ),
                    _IntroHighlight(
                      title: 'Adaptive audio cues',
                      description:
                          'Audio alerts automatically adapt to whether Toll Cam Finder is in the foreground, keeping guidance relevant without overwhelming you.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<IntroController>().markIntroSeen();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.map);
                    }
                  },
                  child: const Text('Let\'s drive'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroHighlight extends StatelessWidget {
  const _IntroHighlight({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
