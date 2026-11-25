import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/core/services/shared_preferences_points_service.dart';
import 'package:ecotrash/features/rewards/data/repositories/shared_preferences_reward_repository.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/rewards_config.dart';
import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_service.dart';
import 'package:ecotrash/features/rewards/domain/services/rewards_notification_service.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('point rules cover waste, pickup bonuses, and impact estimates', () {
    expect(RewardsConfig.pointsPerKgByWasteType, {
      'plastic': 10,
      'paperCardboard': 6,
      'glass': 8,
      'metal': 15,
      'smallElectronics': 20,
    });
    expect(RewardsConfig.pointsForWeights({'organic': 2, 'hazardous': 1}), 0);
    expect(
      RewardsConfig.calculatePickupPoints({'plastic': 10}, isFirstPickup: true),
      130,
    );
    expect(RewardsConfig.co2SavedKg({'metal': 2}), 8);
  });

  test(
    'duplicate earned references and concurrent spending stay idempotent',
    () async {
      final service = SharedPreferencesPointsService();
      await service.addPoints(
        points: 100,
        source: PointsSource.directDeposit,
        description: 'Setor langsung',
        referenceId: 'deposit-unique',
      );
      await service.addPoints(
        points: 100,
        source: PointsSource.directDeposit,
        description: 'Setor langsung duplikat',
        referenceId: 'deposit-unique',
      );

      final spends = await Future.wait([
        service.spendPoints(
          points: 80,
          referenceId: 'redeem-one',
          description: 'Reward 1',
        ),
        service.spendPoints(
          points: 80,
          referenceId: 'redeem-two',
          description: 'Reward 2',
        ),
      ]);

      expect(
        spends.whereType<ResultSuccess<PointsTransaction>>(),
        hasLength(1),
      );
      expect(
        spends.whereType<ResultFailure<PointsTransaction>>(),
        hasLength(1),
      );
      expect(await service.getBalance(), 20);
      expect(await service.getTotalEarned(), 100);
      expect(await service.getTransactions(), hasLength(2));
    },
  );

  test(
    'transaction references cannot be reused across different operations',
    () async {
      final service = SharedPreferencesPointsService();
      await service.addPoints(
        points: 100,
        source: PointsSource.directDeposit,
        description: 'Setor',
        referenceId: 'shared-reference',
      );

      final spend = await service.spendPoints(
        points: 100,
        referenceId: 'shared-reference',
        description: 'Reward',
      );
      expect(spend, isA<ResultFailure<PointsTransaction>>());

      await expectLater(
        service.addPoints(
          points: 50,
          source: PointsSource.refund,
          description: 'Refund dengan referensi terpakai',
          referenceId: 'shared-reference',
        ),
        throwsA(isA<PointsServiceException>()),
      );
      expect(await service.getBalance(), 100);
    },
  );

  test(
    'redemption enforces stock, active state, daily limit and phone format',
    () async {
      final points = SharedPreferencesPointsService();
      await points.addPoints(
        points: 10000,
        source: PointsSource.directDeposit,
        description: 'Setor',
        referenceId: 'deposit',
      );
      final container = _container(points);
      addTearDown(container.dispose);
      final controller = container.read(rewardsControllerProvider.notifier);
      await container.read(rewardsControllerProvider.future);

      await expectLater(
        controller.redeem(Reward.catalog.firstWhere((item) => item.stock == 0)),
        throwsA(
          isA<RewardRedemptionException>().having(
            (error) => error.message,
            'message',
            contains('Stok'),
          ),
        ),
      );
      await expectLater(
        controller.redeem(
          Reward(
            id: 'inactive',
            title: 'Reward nonaktif',
            description: '',
            pointsCost: 1,
            category: RewardCategory.voucherDiskon,
            active: false,
          ),
        ),
        throwsA(isA<RewardRedemptionException>()),
      );
      await expectLater(
        controller.redeem(
          Reward.catalog.first,
          ewalletProvider: 'GoPay',
          targetPhone: '081234',
        ),
        throwsA(isA<RewardRedemptionException>()),
      );

      final ecoBag = Reward.catalog.firstWhere((item) => item.id == 'eco-bag');
      for (var index = 0; index < RewardsConfig.maxRedemptionsPerDay; index++) {
        await controller.redeem(ecoBag);
      }
      await expectLater(
        controller.redeem(ecoBag),
        throwsA(
          isA<RewardRedemptionException>().having(
            (error) => error.message,
            'message',
            contains('3 reward per hari'),
          ),
        ),
      );
    },
  );

  test('cancellation within 24 hours refunds points once', () async {
    final points = SharedPreferencesPointsService();
    await points.addPoints(
      points: 1000,
      source: PointsSource.directDeposit,
      description: 'Setor',
      referenceId: 'deposit',
    );
    final container = _container(points);
    addTearDown(container.dispose);
    final controller = container.read(rewardsControllerProvider.notifier);
    await container.read(rewardsControllerProvider.future);

    final voucher = await controller.redeem(
      Reward.catalog.firstWhere((item) => item.id == 'eco-bag'),
    );
    expect(await points.getBalance(), 500);
    await controller.cancelVoucher(voucher.id);
    await expectLater(
      controller.cancelVoucher(voucher.id),
      throwsA(isA<RewardRedemptionException>()),
    );

    expect(await points.getBalance(), 1000);
    expect(
      (await SharedPreferencesRewardRepository().getVoucher(voucher.id))
          ?.status,
      RewardVoucherStatus.cancelled,
    );
    expect(
      (await points.getHistory(source: PointsSource.refund)).single.points,
      500,
    );
  });

  test('idempotency key cannot redeem a different reward', () async {
    final points = SharedPreferencesPointsService();
    await points.addPoints(
      points: 10000,
      source: PointsSource.directDeposit,
      description: 'Setor',
      referenceId: 'deposit',
    );
    final container = _container(points);
    addTearDown(container.dispose);
    final controller = container.read(rewardsControllerProvider.notifier);
    await container.read(rewardsControllerProvider.future);
    final ecoBag = Reward.catalog.firstWhere((item) => item.id == 'eco-bag');
    final first = await controller.redeem(
      ecoBag,
      idempotencyKey: 'same-request',
    );
    expect(first.rewardId, ecoBag.id);

    await expectLater(
      controller.redeem(
        Reward.catalog.first,
        ewalletProvider: 'DANA',
        targetPhone: '081234567890',
        idempotencyKey: 'same-request',
      ),
      throwsA(isA<RewardRedemptionException>()),
    );
    expect(await points.getBalance(), 9500);
  });

  test(
    'failed e-wallet transfer refunds points and updates voucher status',
    () async {
      final points = SharedPreferencesPointsService();
      await points.addPoints(
        points: 1000,
        source: PointsSource.directDeposit,
        description: 'Setor',
        referenceId: 'deposit',
      );
      final container = ProviderContainer(
        overrides: [
          pointsServiceProvider.overrideWithValue(points),
          ewalletPayoutServiceProvider.overrideWithValue(
            _FailingPayoutService(),
          ),
          ewalletPayoutDelayProvider.overrideWithValue(Duration.zero),
          rewardsNotificationServiceProvider.overrideWithValue(
            _NoopRewardsNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(rewardsControllerProvider.notifier);
      await container.read(rewardsControllerProvider.future);

      final voucher = await controller.redeem(
        Reward.catalog.first,
        ewalletProvider: 'DANA',
        targetPhone: '+6281234567890',
      );
      for (var index = 0; index < 100 && controller.isRedeeming; index++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      expect(await points.getBalance(), 1000);
      expect(
        (await SharedPreferencesRewardRepository().getVoucher(voucher.id))
            ?.status,
        RewardVoucherStatus.failed,
      );
      expect(
        (await points.getHistory(source: PointsSource.refund)),
        hasLength(1),
      );
    },
  );
}

ProviderContainer _container(SharedPreferencesPointsService points) =>
    ProviderContainer(
      overrides: [
        pointsServiceProvider.overrideWithValue(points),
        ewalletPayoutDelayProvider.overrideWithValue(Duration.zero),
        rewardsNotificationServiceProvider.overrideWithValue(
          _NoopRewardsNotificationService(),
        ),
      ],
    );

class _NoopRewardsNotificationService implements RewardsNotificationService {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> redemptionSucceeded(RewardVoucher voucher) async {}

  @override
  Future<void> scheduleExpiryReminder(RewardVoucher voucher) async {}
}

class _FailingPayoutService implements EwalletPayoutService {
  @override
  Future<String> createPayoutCode({
    required String redemptionId,
    required int amountRupiah,
  }) async {
    throw StateError('Penyedia e-wallet demo tidak tersedia.');
  }
}
