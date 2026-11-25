import 'package:ecotrash/features/rewards/data/repositories/shared_preferences_reward_repository.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/presentation/reward_voucher_detail_page.dart';
import 'package:ecotrash/features/rewards/presentation/rewards_vouchers_page.dart';
import 'package:ecotrash/features/rewards/presentation/widgets/reward_catalog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('catalog labels rewards that exceed the current balance', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RewardCatalogCard(
              reward: Reward.catalog.firstWhere((item) => item.id == 'eco-bag'),
              balance: 0,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Poin kurang'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('active voucher shows QR and use action', (tester) async {
    final voucher = _voucher(id: 'active-voucher', code: 'ECO-1234-ABCD');
    await SharedPreferencesRewardRepository().saveVoucher(voucher);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RewardVoucherDetailPage(voucherId: 'active-voucher'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.byKey(const Key('voucher-use')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('voucher-mark-used')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('voucher-mark-used')), findsOneWidget);
  });

  testWidgets('voucher list separates active and used vouchers', (
    tester,
  ) async {
    final repository = SharedPreferencesRewardRepository();
    await repository.saveVoucher(_voucher(id: 'active', code: 'ECO-ACTI-0001'));
    await repository.saveVoucher(
      _voucher(
        id: 'used',
        code: 'ECO-USED-0002',
      ).copyWith(usedAt: DateTime.now()),
    );
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: RewardsVouchersPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active reward'), findsOneWidget);
    expect(find.text('Used reward'), findsNothing);
    await tester.tap(find.text('Terpakai').first);
    await tester.pumpAndSettle();
    expect(find.text('Used reward'), findsOneWidget);
    expect(find.text('Active reward'), findsNothing);
  });

  testWidgets('empty voucher state prompts the user to visit the catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: RewardsVouchersPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada voucher aktif.'), findsOneWidget);
    expect(find.text('Cari reward'), findsOneWidget);
  });
}

RewardVoucher _voucher({required String id, required String code}) {
  final now = DateTime.now();
  return RewardVoucher(
    id: id,
    rewardId: 'eco-bag',
    title: id == 'used' ? 'Used reward' : 'Active reward',
    code: code,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 30)),
    merchant: 'Bumi Store',
  );
}
