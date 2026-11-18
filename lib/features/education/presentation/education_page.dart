import 'package:ecotrash/core/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class EducationPage extends StatelessWidget {
  const EducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Edukasi Pilah Sampah',
      description: 'Pelajari kebiasaan sederhana untuk bumi yang lebih bersih.',
      icon: Icons.menu_book_outlined,
    );
  }
}
