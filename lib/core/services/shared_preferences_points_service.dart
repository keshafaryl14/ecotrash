import 'dart:convert';

import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPointsService implements PointsService {
  static const _pointsLedgerKey = 'eco_points_ledger';

  @override
  Future<int> getBalance() async => (await _readLedger())['totalPoints'] as int;

  @override
  Future<int> getLifetimePoints() async {
    final ledger = await _readLedger();
    return ledger['lifetimePoints'] as int? ?? ledger['totalPoints'] as int;
  }

  @override
  Future<List<PointsTransaction>> getTransactions() async {
    final rawTransactions =
        (await _readLedger())['transactions'] as List<dynamic>;
    final transactions = rawTransactions
        .map((raw) => PointsTransaction.fromJson(raw as Map<String, dynamic>))
        .toList();
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions;
  }

  @override
  Future<void> addPoints({
    required int points,
    required PointsSource source,
    required String description,
    String? referenceId,
  }) async {
    if (points <= 0 || source == PointsSource.redemption) {
      throw const PointsServiceException(
        'Jumlah atau sumber poin tidak valid.',
      );
    }
    final ledger = await _readLedger();
    final transactions = ledger['transactions'] as List<dynamic>;
    if (_hasReference(transactions, referenceId)) {
      return;
    }
    final now = DateTime.now();
    final transaction = PointsTransaction(
      id: now.microsecondsSinceEpoch.toString(),
      points: points,
      direction: PointsTransactionDirection.earned,
      source: source,
      description: description,
      createdAt: now,
      referenceId: referenceId,
    );
    await _saveLedger({
      ...ledger,
      'totalPoints': (ledger['totalPoints'] as int) + points,
      'lifetimePoints':
          (ledger['lifetimePoints'] as int) +
          (source == PointsSource.systemAdjustment ? 0 : points),
      'transactions': [...transactions, transaction.toJson()],
    });
  }

  @override
  Future<void> redeemPoints({
    required int points,
    required String description,
    required String referenceId,
  }) async {
    if (points <= 0 || referenceId.trim().isEmpty) {
      throw const PointsServiceException('Penukaran poin tidak valid.');
    }
    final ledger = await _readLedger();
    final transactions = ledger['transactions'] as List<dynamic>;
    if (_hasReference(transactions, referenceId)) {
      return;
    }
    final balance = ledger['totalPoints'] as int;
    if (balance < points) {
      throw const InsufficientPointsException();
    }
    final now = DateTime.now();
    final transaction = PointsTransaction(
      id: now.microsecondsSinceEpoch.toString(),
      points: points,
      direction: PointsTransactionDirection.redeemed,
      source: PointsSource.redemption,
      description: description,
      createdAt: now,
      referenceId: referenceId,
    );
    await _saveLedger({
      ...ledger,
      'totalPoints': balance - points,
      'transactions': [...transactions, transaction.toJson()],
    });
  }

  @override
  Future<void> awardPickupCompletion({
    required String orderId,
    required int points,
  }) async {
    if (points < 0) {
      throw const PointsServiceException('Jumlah poin tidak valid.');
    }
    final ledger = await _readLedger();
    final awarded = (ledger['awardedOrderIds'] as List<dynamic>).cast<String>();
    if (awarded.contains(orderId)) {
      return;
    }
    if (points > 0) {
      await addPoints(
        points: points,
        source: PointsSource.pickup,
        description: 'Poin penjemputan selesai',
        referenceId: 'pickup:$orderId',
      );
    }
    final latestLedger = await _readLedger();
    await _saveLedger({
      ...latestLedger,
      'awardedOrderIds': [...awarded, orderId],
    });
  }

  Future<Map<String, dynamic>> _readLedger() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_pointsLedgerKey);
    if (stored == null) {
      return _emptyLedger();
    }
    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, dynamic> ||
        decoded['totalPoints'] is! int ||
        decoded['awardedOrderIds'] is! List) {
      throw const PointsServiceException('Data saldo poin tidak valid.');
    }
    return {
      ..._emptyLedger(),
      ...decoded,
      'lifetimePoints':
          decoded['lifetimePoints'] as int? ?? decoded['totalPoints'] as int,
      'transactions': decoded['transactions'] is List
          ? decoded['transactions'] as List<dynamic>
          : <dynamic>[],
    };
  }

  Map<String, dynamic> _emptyLedger() => {
    'totalPoints': 0,
    'lifetimePoints': 0,
    'awardedOrderIds': <String>[],
    'transactions': <dynamic>[],
  };

  bool _hasReference(List<dynamic> transactions, String? referenceId) {
    if (referenceId == null) {
      return false;
    }
    return transactions.any(
      (raw) => raw is Map<String, dynamic> && raw['referenceId'] == referenceId,
    );
  }

  Future<void> _saveLedger(Map<String, dynamic> ledger) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _pointsLedgerKey,
      jsonEncode(ledger),
    );
    if (!saved) {
      throw const PointsServiceException('Data poin tidak dapat disimpan.');
    }
  }
}
