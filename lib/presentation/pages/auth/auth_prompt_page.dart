import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../services/supabase_service.dart';

class AuthPromptPage extends StatelessWidget {
  const AuthPromptPage({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.login);
  }

  void _goToSignUp(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isConfigured) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Supabase credentials are missing. Add your project details to '
              'enable authentication.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Access your profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Log in to view your profile or create a new account to get started.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => _goToLogin(context),
              child: const Text('Log in'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _goToSignUp(context),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
