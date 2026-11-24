import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/presentation/providers/pickup_order_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PickupPage extends ConsumerWidget {
  const PickupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pickupOrderControllerProvider, (previous, next) {
      final previousOrders = previous?.asData?.value;
      final completedOrders = next.asData?.value;
      if (previousOrders == null || completedOrders == null) {
        return;
      }
      for (final order in completedOrders.where(
        (item) => item.status == PickupOrderStatus.completed,
      )) {
        final wasCompleted = previousOrders.any(
          (previousOrder) =>
              previousOrder.id == order.id &&
              previousOrder.status == PickupOrderStatus.completed,
        );
        if (!wasCompleted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Penjemputan selesai! ${order.estimatedPoints} poin masuk.',
                ),
                action: SnackBarAction(
                  label: 'Rewards',
                  onPressed: () => context.go(AppRoutes.rewards),
                ),
              ),
            );
        }
      }
    });
    final orders = ref.watch(pickupOrderControllerProvider);

    return orders.when(
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat pesanan'),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44),
              const SizedBox(height: 12),
              Text('Pesanan gagal dimuat: $error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(pickupOrderControllerProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (items) => _PickupOrdersContent(orders: items),
    );
  }
}

class _PickupOrdersContent extends StatelessWidget {
  const _PickupOrdersContent({required this.orders});

  final List<PickupOrder> orders;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Layanan Penjemputan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Atur jadwal dan pantau status pesananmu.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  key: const Key('pickup-create-order'),
                  onPressed: () => context.push(AppRoutes.pickupNew),
                  icon: const Icon(Icons.add),
                  label: const Text('Pesan'),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrderList(
                  orders: orders
                      .where((order) => order.status.isActive)
                      .toList(),
                  emptyMessage: 'Belum ada pesanan aktif.',
                ),
                _OrderList(
                  orders: orders
                      .where((order) => !order.status.isActive)
                      .toList(),
                  emptyMessage: 'Riwayat pesanan masih kosong.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.emptyMessage});

  final List<PickupOrder> orders;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(emptyMessage, key: const Key('pickup-empty-state')),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.push(AppRoutes.pickupNew),
                child: const Text('Jadwalkan penjemputan'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const Key('pickup-order-list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final date = MaterialLocalizations.of(context)
            .formatMediumDate(order.pickupAt);
        return Card(
          child: ListTile(
            key: Key('pickup-order-${order.id}'),
            onTap: () => context.push(
              AppRoutes.pickupDetail.replaceFirst(':id', order.id),
              extra: order.id,
            ),
            leading: CircleAvatar(
              child: Icon(
                order.status.isActive
                    ? Icons.local_shipping_outlined
                    : Icons.recycling_outlined,
              ),
            ),
            title: Text('Penjemputan $date'),
            subtitle: Text(
              '${order.totalWeightKg.toStringAsFixed(1)} kg · '
              '${order.status.label}',
              maxLines: 2,
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
