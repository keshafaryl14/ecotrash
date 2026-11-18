import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/auth/presentation/auth_error_message.dart';
import 'package:ecotrash/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final signedOut = await ref.read(authControllerProvider.notifier).signOut();
    if (signedOut && context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ProfileMessage(
        message: authErrorMessage(error),
        actionLabel: 'Coba lagi',
        onPressed: () => ref.invalidate(authControllerProvider),
      ),
      data: (user) {
        if (user == null) {
          return _ProfileMessage(
            message: 'Tidak ada sesi aktif.',
            actionLabel: 'Masuk',
            onPressed: () => context.go(AppRoutes.login),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(
                user.name.characters.first.toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              key: const Key('profile-name'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              key: const Key('profile-sign-out'),
              onPressed: authState.isLoading
                  ? null
                  : () => _signOut(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
