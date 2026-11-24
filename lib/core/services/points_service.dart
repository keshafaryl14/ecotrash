import 'package:ecotrash/core/services/points_transaction.dart';

abstract interface class PointsService {
  Future<int> getBalance();

  Future<int> getLifetimePoints();

  Future<List<PointsTransaction>> getTransactions();

  Future<void> addPoints({
    required int points,
    required PointsSource source,
    required String description,
    String? referenceId,
  });

  Future<void> redeemPoints({
    required int points,
    required String description,
    required String referenceId,
  });

  Future<void> awardPickupCompletion({
    required String orderId,
    required int points,
  });
}

class PointsServiceException implements Exception {
  const PointsServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InsufficientPointsException extends PointsServiceException {
  const InsufficientPointsException()
    : super('Poin kamu belum cukup untuk menukar reward ini.');
}
