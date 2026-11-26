import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/widgets/eco_logo.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const EcoLogo(size: 28, variant: EcoLogoVariant.horizontal),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masuk sebagai',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih pengalaman yang sesuai dengan kebutuhanmu.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _RoleCard(
                role: UserRole.pengguna,
                icon: Icons.person_outline,
                title: 'Pengguna',
                subtitle: 'Saya ingin menyetor dan mendaur ulang sampah',
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role: UserRole.mitra,
                icon: Icons.store_mall_directory_outlined,
                title: 'Mitra Bank Sampah',
                subtitle: 'Saya mengelola bank sampah atau pengepul',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.go(AppRoutes.login, extra: role),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(radius: 32, child: Icon(icon, size: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
