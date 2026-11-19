import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/repositories/pickup_order_repository.dart';
import 'package:ecotrash/features/pickup/presentation/providers/pickup_order_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PickupOrderDetailPage extends ConsumerWidget {
  const PickupOrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(pickupOrderControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penjemputan')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Detail pesanan gagal dimuat: $error'),
          ),
        ),
        data: (allOrders) {
          final matches = allOrders.where((order) => order.id == orderId);
          if (matches.isEmpty) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }
          return _PickupOrderDetailContent(order: matches.first);
        },
      ),
    );
  }
}

class _PickupOrderDetailContent extends ConsumerWidget {
  const _PickupOrderDetailContent({required this.order});

  final PickupOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(order.pickupAt);
    final statusIndex = order.status.index.clamp(0, 3);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan #${order.id}',
                  key: const Key('pickup-detail-order-id'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  order.status.label,
                  key: const Key('pickup-detail-status'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (order.status.isActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Status demo akan diperbarui otomatis setiap beberapa detik.',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Lini masa', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (order.status == PickupOrderStatus.cancelled)
          const ListTile(
            key: Key('pickup-timeline-cancelled'),
            leading: Icon(Icons.cancel_outlined),
            title: Text('Pesanan dibatalkan'),
          )
        else
          for (var index = 0; index < _activeStatuses.length; index++)
            _TimelineStep(
              key: Key('pickup-timeline-${_activeStatuses[index].name}'),
              status: _activeStatuses[index],
              complete: index < statusIndex,
              current: index == statusIndex,
              last: index == _activeStatuses.length - 1,
            ),
        const Divider(height: 28),
        _DetailRow(
          title: 'Jadwal',
          value: '$date · ${order.timeSlot}',
          icon: Icons.calendar_month_outlined,
        ),
        _DetailRow(
          title: 'Alamat',
          value: order.address,
          icon: Icons.location_on_outlined,
        ),
        _DetailRow(
          title: 'Total berat',
          value: '${order.totalWeightKg.toStringAsFixed(1)} kg',
          icon: Icons.scale_outlined,
        ),
        for (final entry in order.wasteWeightsKg.entries)
          _DetailRow(
            title: entry.key.label,
            value: '${entry.value.toStringAsFixed(1)} kg',
            icon: Icons.recycling_outlined,
          ),
        if (order.courierNote.isNotEmpty)
          _DetailRow(
            title: 'Catatan kurir',
            value: order.courierNote,
            icon: Icons.sticky_note_2_outlined,
          ),
        if (order.status == PickupOrderStatus.completed)
          Card(
            child: ListTile(
              leading: const Icon(Icons.eco_outlined),
              title: const Text('Poin diperoleh'),
              trailing: Text(
                '+${order.estimatedPoints}',
                key: const Key('pickup-earned-points'),
              ),
            ),
          ),
        if (order.status.canBeCancelled) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('pickup-cancel-order'),
            onPressed: () => _confirmCancellation(context, ref),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Batalkan pesanan'),
          ),
        ],
        if (order.status == PickupOrderStatus.courierEnRoute)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Pembatalan sudah ditutup karena kurir sedang menuju lokasi.',
              key: Key('pickup-cancel-locked-message'),
              textAlign: TextAlign.center,
            ),
          ),
        if (order.status == PickupOrderStatus.cancelled)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Pesanan ini telah dibatalkan.',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Future<void> _confirmCancellation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text(
          'Jadwal penjemputan ini akan dibatalkan dan tidak dapat dipulihkan.',
        ),
        actions: [
          TextButton(
            key: const Key('pickup-cancel-dialog-dismiss'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Jangan batalkan'),
          ),
          FilledButton(
            key: const Key('pickup-cancel-dialog-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      final warning = await ref
          .read(pickupOrderControllerProvider.notifier)
          .cancelOrder(order.id);
      if (warning != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(warning)));
      }
    } on PickupOrderException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesanan gagal dibatalkan: $error')),
        );
      }
    }
  }
}

const _activeStatuses = [
  PickupOrderStatus.waitingConfirmation,
  PickupOrderStatus.confirmed,
  PickupOrderStatus.courierEnRoute,
  PickupOrderStatus.completed,
];

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.complete,
    required this.current,
    required this.last,
    super.key,
  });

  final PickupOrderStatus status;
  final bool complete;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = complete || current
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(DateTime.now());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Icon(
                  complete
                      ? Icons.check_circle
                      : current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  key: Key('pickup-timeline-icon-${status.name}'),
                  color: color,
                  size: 22,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: current ? FontWeight.bold : null,
                    ),
                  ),
                  if (complete || current)
                    Text(
                      current && !complete ? 'Sedang berlangsung' : date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
