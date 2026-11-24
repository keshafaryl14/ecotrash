import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:ecotrash/features/auth/presentation/auth_error_message.dart';
import 'package:ecotrash/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _shortcuts = [
    _HomeShortcut(
      title: 'Smart Scan',
      description: 'Kenali jenis sampah',
      icon: Icons.document_scanner_outlined,
      route: AppRoutes.scan,
    ),
    _HomeShortcut(
      title: 'Bank Sampah Terdekat',
      description: 'Cari mitra daur ulang',
      icon: Icons.map_outlined,
      route: AppRoutes.map,
    ),
    _HomeShortcut(
      title: 'Jadwalkan Penjemputan',
      description: 'Setor sampah dari rumah',
      icon: Icons.local_shipping_outlined,
      route: AppRoutes.pickup,
    ),
    _HomeShortcut(
      title: 'Tukar Poin',
      description: 'Lihat katalog rewards',
      icon: Icons.card_giftcard_outlined,
      route: AppRoutes.rewards,
    ),
  ];

  static const _todayTip = (
    title: 'Kosongkan dan bilas botol plastik',
    description:
        'Botol yang bersih lebih mudah dipilah dan didaur ulang. Pisahkan '
        'tutupnya jika aturan bank sampah setempat memintanya.',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat profil'),
      ),
      error: (error, _) => _HomeMessage(
        icon: Icons.error_outline,
        message: authErrorMessage(error),
        actionLabel: 'Coba lagi',
        onPressed: () => ref.invalidate(authControllerProvider),
      ),
      data: (user) {
        if (user == null) {
          return _HomeMessage(
            icon: Icons.person_outline,
            message: 'Sesi belum tersedia. Silakan masuk kembali.',
            actionLabel: 'Masuk',
            onPressed: () => context.go(AppRoutes.login),
          );
        }
        return _HomeContent(user: user);
      },
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = ref.watch(pointsBalanceProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${user.name}!',
                    key: const Key('home-greeting'),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Siap membuat dampak baik hari ini?',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              key: const Key('home-profile'),
              tooltip: 'Buka profil',
              onPressed: () => context.go(AppRoutes.profile),
              icon: const Icon(Icons.person_outline),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 36,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poin Eco kamu',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      points.when(
                        loading: () =>
                            const Text('Memuat…', key: Key('home-points')),
                        error: (error, _) => Text(
                          'Tidak tersedia',
                          key: const Key('home-points'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        data: (value) => Text(
                          '$value poin',
                          key: const Key('home-points'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tukar poin',
                  onPressed: () => context.go(AppRoutes.rewards),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Aksi cepat', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: HomePage._shortcuts.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final shortcut = HomePage._shortcuts[index];
            return _ShortcutCard(
              shortcut: shortcut,
              onTap: () => context.go(shortcut.route),
            );
          },
        ),
        const SizedBox(height: 28),
        Text('Tips Hari Ini', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        HomePage._todayTip.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        HomePage._todayTip.description,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('home-education-link'),
            onPressed: () => context.go(AppRoutes.education),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Buka panduan edukasi'),
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.shortcut, required this.onTap});

  final _HomeShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(shortcut.icon, color: colorScheme.primary, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortcut.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortcut.description,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _HomeShortcut {
  const _HomeShortcut({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;
}
