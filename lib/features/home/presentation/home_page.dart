import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _actions = [
    _HomeAction(
      title: 'Smart Scan',
      description: 'Kenali jenis sampah',
      icon: Icons.document_scanner_outlined,
      path: AppRoutes.scan,
    ),
    _HomeAction(
      title: 'Peta Bank Sampah',
      description: 'Temukan lokasi terdekat',
      icon: Icons.map_outlined,
      path: AppRoutes.map,
    ),
    _HomeAction(
      title: 'Penjemputan',
      description: 'Jadwalkan setor dari rumah',
      icon: Icons.local_shipping_outlined,
      path: AppRoutes.pickup,
    ),
    _HomeAction(
      title: 'Belajar Pilah',
      description: 'Tips kelola sampah',
      icon: Icons.menu_book_outlined,
      path: AppRoutes.education,
    ),
    _HomeAction(
      title: 'Profil',
      description: 'Kelola akun EcoTrash',
      icon: Icons.person_outline,
      path: AppRoutes.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Langkah kecil, dampak besar 🌱',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Mulai perjalanan memilah dan mendaur ulang sampahmu.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                      Text(
                        '0 poin',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Lihat reward',
                  onPressed: () => context.go(AppRoutes.rewards),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Mulai dari sini', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: _actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final action = _actions[index];
            return _ActionCard(
              action: action,
              onTap: () => context.go(action.path),
            );
          },
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onTap});

  final _HomeAction action;
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
              Icon(action.icon, color: colorScheme.primary, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.description,
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

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.path,
  });

  final String title;
  final String description;
  final IconData icon;
  final String path;
}
