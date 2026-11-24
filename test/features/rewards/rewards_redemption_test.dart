import 'dart:async';

import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/core/services/shared_preferences_points_service.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_service.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('redeems a reward once and saves its code and transaction', () async {
    final points = SharedPreferencesPointsService();
    await points.addPoints(
      points: 1000,
      source: PointsSource.directDeposit,
      description: 'Setoran langsung',
    );
    final container = ProviderContainer(
      overrides: [pointsServiceProvider.overrideWithValue(points)],
    );
    addTearDown(container.dispose);
    await container.read(rewardsControllerProvider.future);

    final reward = Reward.catalog.firstWhere(
      (item) => item.id == 'eco-10-percent',
    );
    final voucher = await container
        .read(rewardsControllerProvider.notifier)
        .redeem(reward);

    expect(voucher.code, startsWith('ECO-'));
    expect(await points.getBalance(), 500);
    expect(
      container.read(rewardsControllerProvider).requireValue.single.id,
      voucher.id,
    );
    final history = await points.getTransactions();
    expect(history.first.direction, PointsTransactionDirection.redeemed);
  });

  test(
    'blocks duplicate in-flight redemption and rejects low balance',
    () async {
      final points = SharedPreferencesPointsService();
      await points.addPoints(
        points: 1000,
        source: PointsSource.directDeposit,
        description: 'Setoran langsung',
      );
      final payout = _PendingPayoutService();
      final container = ProviderContainer(
        overrides: [
          pointsServiceProvider.overrideWithValue(points),
          ewalletPayoutServiceProvider.overrideWithValue(payout),
        ],
      );
      addTearDown(container.dispose);
      await container.read(rewardsControllerProvider.future);

      final controller = container.read(rewardsControllerProvider.notifier);
      final firstRedemption = controller.redeem(Reward.catalog.first);
      await expectLater(
        controller.redeem(Reward.catalog.first),
        throwsA(isA<RewardRedemptionException>()),
      );
      payout.complete('ECO10000-TEST');
      await firstRedemption;
      expect(await points.getBalance(), 0);

      await expectLater(
        controller.redeem(Reward.catalog.first),
        throwsA(isA<RewardInsufficientPointsException>()),
      );
    },
  );
}

class _PendingPayoutService implements EwalletPayoutService {
  final _completion = Completer<String>();

  void complete(String code) => _completion.complete(code);

  @override
  Future<String> createPayoutCode({
    required String redemptionId,
    required int amountRupiah,
  }) => _completion.future;
}
