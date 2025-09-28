import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../services/supabase_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final client = SupabaseService.clientOrNull;
    if (client == null) {
      return;
    }
    _user = client.auth.currentUser;
    _authSubscription = client.auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;
      setState(() {
        _user = authState.session?.user;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    final client = SupabaseService.clientOrNull;
    if (client == null) {
      return;
    }
    await client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.map,
      (route) => false,
    );
  }

  void _goToAuthPrompt() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.authPrompt,
      (route) => route.settings.name == AppRoutes.map,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isConfigured) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: _buildConfigurationWarning(context),
      );
    }

    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: user == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'You are not logged in',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Log in or create an account to view your profile.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _goToAuthPrompt,
                    child: const Text('Go to authentication'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(user.email ?? 'Unknown user'),
                      subtitle: const Text('Email'),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: _signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildConfigurationWarning(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Supabase credentials are missing. Add your project details to '
          'enable authentication.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
