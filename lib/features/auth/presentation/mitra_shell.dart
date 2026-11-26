import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MitraShell extends StatelessWidget {
  const MitraShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const _destinations = [
    (AppRoutes.mitraDashboard, 'Dashboard', Icons.dashboard_outlined),
    (AppRoutes.mitraRequests, 'Permintaan', Icons.assignment_outlined),
    (AppRoutes.mitraStock, 'Stok', Icons.inventory_2_outlined),
    (AppRoutes.mitraHistory, 'Riwayat', Icons.history),
    (AppRoutes.mitraProfile, 'Profil Mitra', Icons.store_outlined),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere((item) => item.$1 == location);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('EcoTrash Mitra')),
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => context.go(_destinations[index].$1),
      destinations: [
        for (final destination in _destinations)
          NavigationDestination(
            icon: Icon(destination.$3),
            label: destination.$2,
          ),
      ],
    ),
  );
}

class MitraPlaceholderPage extends StatelessWidget {
  const MitraPlaceholderPage({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
