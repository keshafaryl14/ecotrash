import 'dart:async';
import 'dart:convert';

import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/features/rewards/domain/rewards_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPointsService implements PointsService {
  static const _pointsLedgerKey = 'eco_points_ledger';

  final _balanceChanges = StreamController<int>.broadcast();
  Future<void> _writeTail = Future<void>.value();

  @override
  Stream<int> watchBalance() async* {
    yield await getBalance();
    yield* _balanceChanges.stream;
  }

  @override
  Future<int> getBalance() async => (await _readLedger())['totalPoints'] as int;

  @override
  Future<int> getLifetimePoints() => getTotalEarned();

  @override
  Future<int> getTotalEarned() async {
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
  Future<List<PointsTransaction>> getHistory({
    DateTime? month,
    PointsSource? source,
  }) async {
    final transactions = await getTransactions();
    return transactions.where((transaction) {
      final matchesMonth =
          month == null ||
          (transaction.createdAt.year == month.year &&
              transaction.createdAt.month == month.month);
      return matchesMonth && (source == null || transaction.source == source);
    }).toList();
  }

  @override
  Future<void> addPoints({
    required int points,
    required PointsSource source,
    required String description,
    String? referenceId,
  }) => _serialize(() async {
    await _addPointsUnlocked(
      points: points,
      source: source,
      description: description,
      referenceId: referenceId,
    );
  });

  @override
  Future<void> redeemPoints({
    required int points,
    required String description,
    required String referenceId,
  }) async {
    final result = await spendPoints(
      points: points,
      description: description,
      referenceId: referenceId,
    );
    if (result case ResultFailure<PointsTransaction>(:final error)) {
      throw error;
    }
  }

  @override
  Future<Result<PointsTransaction>> spendPoints({
    required int points,
    required String referenceId,
    required String description,
  }) => _serialize(() async {
    if (points <= 0 || referenceId.trim().isEmpty) {
      return const ResultFailure(
        PointsServiceException('Penukaran poin tidak valid.'),
      );
    }
    final ledger = await _readLedger();
    final transactions = ledger['transactions'] as List<dynamic>;
    final existing = _findReference(transactions, referenceId);
    if (existing != null) {
      if (existing.direction == PointsTransactionDirection.redeemed &&
          existing.source == PointsSource.redemption &&
          existing.points == points) {
        return ResultSuccess(existing);
      }
      return const ResultFailure(
        PointsServiceException('Referensi transaksi sudah digunakan.'),
      );
    }
    final balance = ledger['totalPoints'] as int;
    if (balance < points) {
      return const ResultFailure(InsufficientPointsException());
    }
    final transaction = _transaction(
      points: points,
      direction: PointsTransactionDirection.redeemed,
      source: PointsSource.redemption,
      description: description,
      referenceId: referenceId,
    );
    await _saveLedger({
      ...ledger,
      'totalPoints': balance - points,
      'transactions': [...transactions, transaction.toJson()],
    });
    _balanceChanges.add(balance - points);
    return ResultSuccess(transaction);
  });

  @override
  Future<void> refundPoints({
    required int points,
    required String referenceId,
    required String description,
  }) => addPoints(
    points: points,
    source: PointsSource.refund,
    description: description,
    referenceId: referenceId,
  );

  @override
  Future<void> awardPickupCompletion({
    required String orderId,
    required int points,
    double totalWeightKg = 0,
  }) => _serialize(() async {
    if (points < 0 || orderId.trim().isEmpty) {
      throw const PointsServiceException('Data poin penjemputan tidak valid.');
    }
    final ledger = await _readLedger();
    final awarded = (ledger['awardedOrderIds'] as List<dynamic>).cast<String>();
    if (awarded.contains(orderId)) {
      return;
    }
    final bonus = awarded.isEmpty ? RewardsConfig.firstPickupBonus : 0;
    final totalAward = points + bonus;
    final transactions = ledger['transactions'] as List<dynamic>;
    if (totalAward > 0) {
      final transaction = _transaction(
        points: totalAward,
        direction: PointsTransactionDirection.earned,
        source: PointsSource.pickup,
        description: bonus > 0
            ? 'Poin penjemputan selesai termasuk bonus'
            : 'Poin penjemputan selesai',
        referenceId: 'pickup:$orderId',
      );
      await _saveLedger({
        ...ledger,
        'totalPoints': (ledger['totalPoints'] as int) + totalAward,
        'lifetimePoints': (ledger['lifetimePoints'] as int) + totalAward,
        'awardedOrderIds': [...awarded, orderId],
        'transactions': [...transactions, transaction.toJson()],
      });
      _balanceChanges.add((ledger['totalPoints'] as int) + totalAward);
      return;
    }
    await _saveLedger({
      ...ledger,
      'awardedOrderIds': [...awarded, orderId],
    });
  });

  @override
  Future<void> awardQuizBonus({required String referenceId}) => addPoints(
    points: RewardsConfig.perfectQuizBonus,
    source: PointsSource.bonus,
    description: 'Bonus kuis edukasi dengan semua jawaban benar',
    referenceId: 'quiz:$referenceId',
  );

  Future<void> _addPointsUnlocked({
    required int points,
    required PointsSource source,
    required String description,
    String? referenceId,
  }) async {
    if (points <= 0 ||
        source == PointsSource.redemption ||
        (referenceId != null && referenceId.trim().isEmpty)) {
      throw const PointsServiceException(
        'Jumlah, sumber, atau referensi poin tidak valid.',
      );
    }
    final ledger = await _readLedger();
    final transactions = ledger['transactions'] as List<dynamic>;
    final existing = _findReference(transactions, referenceId);
    if (existing != null) {
      if (existing.direction == PointsTransactionDirection.earned &&
          existing.source == source &&
          existing.points == points) {
        return;
      }
      throw const PointsServiceException(
        'Referensi transaksi sudah digunakan.',
      );
    }
    final transaction = _transaction(
      points: points,
      direction: PointsTransactionDirection.earned,
      source: source,
      description: description,
      referenceId: referenceId,
    );
    final balance = (ledger['totalPoints'] as int) + points;
    final isEarned =
        source != PointsSource.refund &&
        source != PointsSource.systemAdjustment;
    await _saveLedger({
      ...ledger,
      'totalPoints': balance,
      'lifetimePoints':
          (ledger['lifetimePoints'] as int) + (isEarned ? points : 0),
      'transactions': [...transactions, transaction.toJson()],
    });
    _balanceChanges.add(balance);
  }

  PointsTransaction _transaction({
    required int points,
    required PointsTransactionDirection direction,
    required PointsSource source,
    required String description,
    String? referenceId,
  }) {
    final now = DateTime.now();
    return PointsTransaction(
      id: now.microsecondsSinceEpoch.toString(),
      points: points,
      direction: direction,
      source: source,
      description: description,
      createdAt: now,
      referenceId: referenceId,
    );
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _writeTail = _writeTail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  PointsTransaction? _findReference(
    List<dynamic> transactions,
    String? referenceId,
  ) {
    if (referenceId == null) {
      return null;
    }
    for (final raw in transactions) {
      if (raw is Map<String, dynamic> && raw['referenceId'] == referenceId) {
        return PointsTransaction.fromJson(raw);
      }
    }
    return null;
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
