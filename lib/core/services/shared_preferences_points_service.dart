import 'dart:convert';

import 'package:ecotrash/core/services/points_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPointsService implements PointsService {
  static const _pointsLedgerKey = 'eco_points_ledger';

  @override
  Future<void> awardPickupCompletion({
    required String orderId,
    required int points,
  }) async {
    if (points < 0) {
      throw const PointsServiceException('Jumlah poin tidak valid.');
    }

    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_pointsLedgerKey);
    final ledger = stored == null
        ? <String, dynamic>{'totalPoints': 0, 'awardedOrderIds': <String>[]}
        : jsonDecode(stored) as Map<String, dynamic>;
    final awarded = (ledger['awardedOrderIds'] as List<dynamic>).cast<String>();
    if (awarded.contains(orderId)) {
      return;
    }

    final totalPoints = ledger['totalPoints'] as int;
    final saved = await preferences.setString(
      _pointsLedgerKey,
      jsonEncode({
        'totalPoints': totalPoints + points,
        'awardedOrderIds': [...awarded, orderId],
      }),
    );
    if (!saved) {
      throw const PointsServiceException('Poin pesanan tidak dapat disimpan.');
    }
  }
}

class PointsServiceException implements Exception {
  const PointsServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
