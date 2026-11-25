import 'package:ecotrash/core/services/points_transaction.dart';

abstract interface class PointsService {
  Stream<int> watchBalance();

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
    double totalWeightKg = 0,
  });

  Future<Result<PointsTransaction>> spendPoints({
    required int points,
    required String referenceId,
    required String description,
  });

  Future<void> refundPoints({
    required int points,
    required String referenceId,
    required String description,
  });

  Future<List<PointsTransaction>> getHistory({
    DateTime? month,
    PointsSource? source,
  });

  Future<int> getTotalEarned();

  Future<void> awardQuizBonus({required String referenceId});
}

sealed class Result<T> {
  const Result();
}

final class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.value);
  final T value;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.error);
  final PointsServiceException error;
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
