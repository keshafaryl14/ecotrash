import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  static const _destinations = [
    _AppDestination(
      label: 'Beranda',
      icon: Icons.home_outlined,
      path: AppRoutes.home,
    ),
    _AppDestination(
      label: 'Scan',
      icon: Icons.document_scanner_outlined,
      path: AppRoutes.scan,
    ),
    _AppDestination(
      label: 'Peta',
      icon: Icons.map_outlined,
      path: AppRoutes.map,
    ),
    _AppDestination(
      label: 'Penjemputan',
      icon: Icons.local_shipping_outlined,
      path: AppRoutes.pickup,
    ),
    _AppDestination(
      label: 'Rewards',
      icon: Icons.card_giftcard_outlined,
      path: AppRoutes.rewards,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _destinations.indexWhere(
      (destination) => destination.path == currentLocation,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('EcoTrash')),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
        onDestinationSelected: (index) {
          context.go(_destinations[index].path);
        },
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}
