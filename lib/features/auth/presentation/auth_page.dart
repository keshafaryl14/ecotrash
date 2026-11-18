import 'package:ecotrash/core/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Masuk atau Daftar',
      description: 'Akun EcoTrash akan tersedia pada tahap berikutnya.',
      icon: Icons.lock_outline,
    );
  }
}
