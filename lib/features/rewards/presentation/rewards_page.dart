import 'package:ecotrash/core/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Rewards & Poin',
      description: 'Tukar poin setoranmu dengan reward menarik.',
      icon: Icons.card_giftcard_outlined,
    );
  }
}
