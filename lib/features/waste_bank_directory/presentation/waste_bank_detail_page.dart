import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class WasteBankDetailPage extends StatelessWidget {
  const WasteBankDetailPage({required this.bank, super.key});

  final WasteBank bank;

  Future<void> _launchExternal(
    BuildContext context,
    Uri uri,
    String failureMessage,
  ) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$failureMessage $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${bank.location.latitude},${bank.location.longitude}',
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Bank Sampah')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: bank.photoUrl == null
                  ? ColoredBox(
                      color: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.recycling_outlined,
                        size: 72,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : Image.network(
                      bank.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            bank.name,
            key: const Key('waste-bank-detail-name'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: colorScheme.tertiary),
              const SizedBox(width: 4),
              Text('${bank.rating.toStringAsFixed(1)} / 5'),
            ],
          ),
          const SizedBox(height: 18),
          _DetailRow(
            icon: Icons.location_on_outlined,
            title: 'Alamat',
            value: bank.address,
          ),
          _DetailRow(
            icon: Icons.schedule_outlined,
            title: 'Jam operasional',
            value: bank.openingHours,
          ),
          _DetailRow(
            icon: Icons.phone_outlined,
            title: 'Kontak',
            value: bank.contact,
          ),
          const SizedBox(height: 16),
          Text(
            'Menerima jenis sampah',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final type in bank.acceptedWasteTypes)
                Chip(
                  avatar: const Icon(Icons.recycling_outlined, size: 18),
                  label: Text(type),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('waste-bank-directions'),
            onPressed: () => _launchExternal(
              context,
              destination,
              'Aplikasi peta tidak dapat dibuka.',
            ),
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Petunjuk Arah'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('waste-bank-contact'),
            onPressed: () => _launchExternal(
              context,
              Uri(scheme: 'tel', path: bank.contact),
              'Aplikasi telepon tidak dapat dibuka.',
            ),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Hubungi'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            key: const Key('waste-bank-pickup'),
            onPressed: () => context.go(AppRoutes.pickup),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Jadwalkan Penjemputan'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}

class WasteBankDetailErrorPage extends StatelessWidget {
  const WasteBankDetailErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Bank Sampah')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Data bank sampah tidak tersedia. Kembali ke peta dan pilih lokasi.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
