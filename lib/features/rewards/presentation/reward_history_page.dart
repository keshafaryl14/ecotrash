import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/core/theme/app_dimensions.dart';
import 'package:ecotrash/core/widgets/app_state_widgets.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardHistoryPage extends ConsumerStatefulWidget {
  const RewardHistoryPage({super.key});

  @override
  ConsumerState<RewardHistoryPage> createState() => _RewardHistoryPageState();
}

class _RewardHistoryPageState extends ConsumerState<RewardHistoryPage> {
  DateTime? _month;
  PointsSource? _source;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(
      filteredPointsHistoryProvider(
        PointsHistoryFilter(month: _month, source: _source),
      ),
    );
    return history.when(
      loading: () =>
          const AppLoadingSkeleton(label: 'Memuat riwayat poin', rows: 4),
      error: (error, _) => AppMessageState(
        icon: Icons.error_outline,
        message: 'Riwayat poin gagal dimuat: $error',
        actionLabel: 'Coba lagi',
        onAction: () => ref.invalidate(
          filteredPointsHistoryProvider(
            PointsHistoryFilter(month: _month, source: _source),
          ),
        ),
      ),
      data: (items) {
        final earned = items
            .where(
              (item) => item.direction == PointsTransactionDirection.earned,
            )
            .fold<int>(0, (total, item) => total + item.points);
        final spent = items
            .where(
              (item) => item.direction == PointsTransactionDirection.redeemed,
            )
            .fold<int>(0, (total, item) => total + item.points);
        return ListView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          children: [
            Text(
              'Riwayat Poin',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimensions.space12),
            Wrap(
              spacing: AppDimensions.space8,
              children: [
                DropdownButton<PointsSource?>(
                  key: const Key('points-source-filter'),
                  value: _source,
                  hint: const Text('Semua sumber'),
                  items: [
                    const DropdownMenuItem<PointsSource?>(
                      value: null,
                      child: Text('Semua sumber'),
                    ),
                    for (final source in PointsSource.values)
                      DropdownMenuItem(
                        value: source,
                        child: Text(source.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _source = value),
                ),
                OutlinedButton.icon(
                  key: const Key('points-month-filter'),
                  onPressed: _chooseMonth,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _month == null ? 'Semua bulan' : _monthLabel(_month!),
                  ),
                ),
                if (_month != null)
                  IconButton(
                    tooltip: 'Hapus filter bulan',
                    onPressed: () => setState(() => _month = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Total(label: 'Poin masuk', value: '+$earned'),
                    _Total(label: 'Poin keluar', value: '-$spent'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            if (items.isEmpty)
              const AppMessageState(
                icon: Icons.history,
                message: 'Belum ada transaksi untuk filter ini.',
              )
            else
              for (final group in _groupByDate(items)) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.space8,
                  ),
                  child: Text(
                    group.$1,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final item in group.$2)
                  _TransactionTile(transaction: item),
              ],
          ],
        );
      },
    );
  }

  Future<void> _chooseMonth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _month ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Pilih bulan transaksi',
    );
    if (selected != null && mounted) {
      setState(() => _month = DateTime(selected.year, selected.month));
    }
  }

  String _monthLabel(DateTime month) =>
      '${_monthNames[month.month - 1]} ${month.year}';

  List<(String, List<PointsTransaction>)> _groupByDate(
    List<PointsTransaction> items,
  ) {
    final grouped = <String, List<PointsTransaction>>{};
    for (final item in items) {
      final date = item.createdAt;
      final label = '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
      grouped.putIfAbsent(label, () => []).add(item);
    }
    return grouped.entries.map((entry) => (entry.key, entry.value)).toList();
  }
}

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label),
      Text(value, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final PointsTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final incoming = transaction.direction == PointsTransactionDirection.earned;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: incoming
              ? colors.primaryContainer
              : colors.errorContainer,
          child: Icon(
            _sourceIcon(transaction.source),
            color: incoming
                ? colors.onPrimaryContainer
                : colors.onErrorContainer,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text(
          '${transaction.source.label} · '
          '${transaction.createdAt.day} '
          '${_monthNames[transaction.createdAt.month - 1]} '
          '${transaction.createdAt.year}',
        ),
        trailing: Text(
          '${incoming ? '+' : '-'}${transaction.points}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: incoming ? colors.primary : colors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _sourceIcon(PointsSource source) => switch (source) {
    PointsSource.smartScan => Icons.document_scanner_outlined,
    PointsSource.pickup => Icons.local_shipping_outlined,
    PointsSource.directDeposit => Icons.recycling_outlined,
    PointsSource.redemption => Icons.card_giftcard_outlined,
    PointsSource.bonus => Icons.celebration_outlined,
    PointsSource.refund => Icons.undo,
    PointsSource.systemAdjustment => Icons.tune,
  };
}
