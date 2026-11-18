import 'package:ecotrash/core/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Profil',
      description: 'Kelola akun dan preferensi EcoTrash-mu.',
      icon: Icons.person_outline,
    );
  }
}
