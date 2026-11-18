import 'package:ecotrash/core/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Selamat datang di EcoTrash',
      description: 'Mulai langkah kecil untuk masa depan yang lebih hijau.',
      icon: Icons.eco_outlined,
    );
  }
}
