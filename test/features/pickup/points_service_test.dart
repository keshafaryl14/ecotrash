import 'dart:convert';

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

    final preferences = await SharedPreferences.getInstance();
    final ledger = jsonDecode(
      preferences.getString('eco_points_ledger')!,
    ) as Map<String, dynamic>;
    expect(ledger['totalPoints'], 30);
    expect(ledger['awardedOrderIds'], ['pickup-1']);
  });
}
