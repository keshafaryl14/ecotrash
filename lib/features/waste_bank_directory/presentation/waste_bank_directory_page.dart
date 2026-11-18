import 'package:ecotrash/core/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class WasteBankDirectoryPage extends StatelessWidget {
  const WasteBankDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Peta Bank Sampah Terdekat',
      description: 'Cari mitra daur ulang di sekitar lokasimu.',
      icon: Icons.map_outlined,
    );
  }
}
