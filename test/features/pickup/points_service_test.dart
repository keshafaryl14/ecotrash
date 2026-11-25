import 'dart:convert';

import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/core/services/shared_preferences_points_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('awards pickup points once per order', () async {
    final service = SharedPreferencesPointsService();
    await service.awardPickupCompletion(orderId: 'pickup-1', points: 30);
    await service.awardPickupCompletion(orderId: 'pickup-1', points: 30);

    expect(await service.getBalance(), 50);
    expect(await service.getLifetimePoints(), 50);
    final transactions = await service.getTransactions();
    expect(transactions, hasLength(1));
    expect(transactions.single.source.label, 'Penjemputan');

    final preferences = await SharedPreferences.getInstance();
    final ledger = jsonDecode(
      preferences.getString('eco_points_ledger')!,
    ) as Map<String, dynamic>;
    expect(ledger['totalPoints'], 50);
    expect(ledger['awardedOrderIds'], ['pickup-1']);
  });

  test(
    'redeems once, keeps lifetime total, and rejects insufficient balance',
    () async {
      final service = SharedPreferencesPointsService();
      await service.addPoints(
        points: 1000,
        source: PointsSource.directDeposit,
        description: 'Setoran langsung',
        referenceId: 'deposit-1',
      );
      await service.redeemPoints(
        points: 500,
        description: 'Voucher ramah lingkungan',
        referenceId: 'reward-1',
      );
      await service.redeemPoints(
        points: 500,
        description: 'Voucher ramah lingkungan',
        referenceId: 'reward-1',
      );

      expect(await service.getBalance(), 500);
      expect(await service.getLifetimePoints(), 1000);
      expect(await service.getTransactions(), hasLength(2));
      await expectLater(
        service.redeemPoints(
          points: 501,
          description: 'Reward tidak terjangkau',
          referenceId: 'reward-2',
        ),
        throwsA(isA<InsufficientPointsException>()),
      );
    },
  );

  test('migrates an existing balance into the lifetime total', () async {
    SharedPreferences.setMockInitialValues({
      'eco_points_ledger': jsonEncode({
        'totalPoints': 120,
        'awardedOrderIds': <String>[],
      }),
    });

    final service = SharedPreferencesPointsService();
    expect(await service.getBalance(), 120);
    expect(await service.getLifetimePoints(), 120);
  });
}
