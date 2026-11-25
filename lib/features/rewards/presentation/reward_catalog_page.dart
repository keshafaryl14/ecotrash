import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/theme/app_dimensions.dart';
import 'package:ecotrash/core/widgets/app_state_widgets.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:ecotrash/features/rewards/presentation/widgets/reward_catalog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RewardCatalogPage extends ConsumerStatefulWidget {
  const RewardCatalogPage({super.key});

  @override
  ConsumerState<RewardCatalogPage> createState() => _RewardCatalogPageState();
}

class _RewardCatalogPageState extends ConsumerState<RewardCatalogPage> {
  final _searchController = TextEditingController();
  RewardCategory? _category;
  RewardSort _sort = RewardSort.popular;

  RewardCatalogFilter get _filter => RewardCatalogFilter(
    category: _category,
    query: _searchController.text,
    sort: _sort,
  );

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(rewardCatalogProvider(_filter));
    final balance = ref.watch(pointsBalanceProvider);
    final points = balance.asData?.value ?? 0;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        Text(
          'Katalog Reward',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppDimensions.space16),
        TextField(
          key: const Key('reward-catalog-search'),
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Cari reward atau merchant',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: AppDimensions.space12),
        Wrap(
          spacing: AppDimensions.space8,
          children: [
            _categoryChip('Semua', null),
            _categoryChip('E-Wallet', RewardCategory.ewallet),
            _categoryChip('Voucher Diskon', RewardCategory.voucherDiskon),
            _categoryChip(
              'Produk Ramah Lingkungan',
              RewardCategory.produkRamahLingkungan,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space8),
        DropdownButtonFormField<RewardSort>(
          key: const Key('reward-catalog-sort'),
          initialValue: _sort,
          decoration: const InputDecoration(
            labelText: 'Urutkan',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: RewardSort.popular,
              child: Text('Terpopuler'),
            ),
            DropdownMenuItem(
              value: RewardSort.lowestPoints,
              child: Text('Poin terendah'),
            ),
            DropdownMenuItem(
              value: RewardSort.highestPoints,
              child: Text('Poin tertinggi'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _sort = value);
            }
          },
        ),
        const SizedBox(height: AppDimensions.space16),
        balance.when(
          loading: () =>
              const AppLoadingSkeleton(label: 'Memuat katalog reward', rows: 4),
          error: (error, _) => AppMessageState(
            icon: Icons.error_outline,
            message:
                'Saldo diperlukan untuk menampilkan kemampuan tukar: $error',
            actionLabel: 'Muat ulang',
            onAction: () => ref.invalidate(pointsBalanceProvider),
          ),
          data: (_) => catalog.when(
            loading: () => const AppLoadingSkeleton(
              label: 'Memuat katalog reward',
              rows: 4,
            ),
            error: (error, _) => AppMessageState(
              icon: Icons.error_outline,
              message: 'Katalog gagal dimuat: $error',
              actionLabel: 'Coba lagi',
              onAction: () => ref.invalidate(rewardCatalogProvider(_filter)),
            ),
            data: (rewards) => rewards.isEmpty
                ? const AppMessageState(
                    icon: Icons.search_off,
                    message: 'Reward tidak ditemukan. Coba kata kunci lain.',
                  )
                : Column(
                    children: [
                      for (final reward in rewards)
                        RewardCatalogCard(
                          reward: reward,
                          balance: points,
                          onTap: () => context.push(
                            AppRoutes.rewardDetail.replaceFirst(
                              ':id',
                              reward.id,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(String label, RewardCategory? category) => ChoiceChip(
    label: Text(label),
    selected: _category == category,
    onSelected: (selected) {
      if (selected) {
        setState(() => _category = category);
      }
    },
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
