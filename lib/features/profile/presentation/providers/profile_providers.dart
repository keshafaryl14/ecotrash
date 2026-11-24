import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/presentation/providers/pickup_order_providers.dart';
import 'package:ecotrash/features/profile/domain/entities/profile_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final orders = await ref.watch(pickupOrderControllerProvider.future);
  final lifetimePoints = await ref.watch(lifetimePointsProvider.future);
  final completed = orders
      .where((order) => order.status == PickupOrderStatus.completed)
      .toList();
  final totalWeight = completed.fold<double>(
    0,
    (total, order) => total + order.totalWeightKg,
  );
  return ProfileStats(
    totalWeightKg: totalWeight,
    totalPoints: lifetimePoints,
    completedPickups: completed.length,
  );
});
