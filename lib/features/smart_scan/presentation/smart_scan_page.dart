import 'package:ecotrash/core/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class SmartScanPage extends StatelessWidget {
  const SmartScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Smart Scan',
      description: 'Pindai sampah untuk mengetahui jenis dan cara mengolahnya.',
      icon: Icons.document_scanner_outlined,
    );
  }
}
