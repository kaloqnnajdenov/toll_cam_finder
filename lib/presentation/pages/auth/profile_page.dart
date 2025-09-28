import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../services/auth_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final email = auth.currentEmail ?? 'Unknown user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                email,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your TollCam account and preferences.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await context.read<AuthController>().logOut();
                    Navigator.of(context).popUntil(
                      ModalRoute.withName(AppRoutes.map),
                    );
                  } on AuthFailure catch (error) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  } catch (error, stackTrace) {
                    debugPrint('Logout error: $error\n$stackTrace');
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Unable to log out. Please try again.'),
                      ),
                    );
                  }
                },
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
