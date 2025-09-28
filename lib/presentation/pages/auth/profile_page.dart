import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../services/auth_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isAvailable) {
      return const _AuthUnavailablePage(title: 'Profile');
    }

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Log in to view your profile.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.login),
                  child: const Text('Go to login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.email ?? 'Unknown user',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'User ID: ${user?.id ?? '-'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final authController = context.read<AuthController>();
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await authController.signOut();
                    if (!navigator.mounted) return;
                    if (result.success) {
                      navigator.pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => route.isFirst,
                      );
                    } else if (result.message != null) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(result.message!)));
                    }
                  },
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthUnavailablePage extends StatelessWidget {
  const _AuthUnavailablePage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Authentication is not configured for this build.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
