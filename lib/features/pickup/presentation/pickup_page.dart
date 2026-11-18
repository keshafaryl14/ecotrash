import 'package:ecotrash/core/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class PickupPage extends StatelessWidget {
  const PickupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Layanan Penjemputan',
      description: 'Atur jadwal penjemputan sampah daur ulang dari rumah.',
      icon: Icons.local_shipping_outlined,
    );
  }
}
