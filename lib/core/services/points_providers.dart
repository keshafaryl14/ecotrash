import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/shared_preferences_points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pointsServiceProvider = Provider<PointsService>((ref) {
  return SharedPreferencesPointsService();
});

final pointsBalanceProvider = FutureProvider<int>((ref) {
  return ref.watch(pointsServiceProvider).getBalance();
});

final lifetimePointsProvider = FutureProvider<int>((ref) {
  return ref.watch(pointsServiceProvider).getLifetimePoints();
});

final pointsTransactionsProvider = FutureProvider<List<PointsTransaction>>((
  ref,
) {
  return ref.watch(pointsServiceProvider).getTransactions();
});
