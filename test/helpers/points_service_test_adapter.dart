import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';

abstract class PointsServiceTestAdapter implements PointsService {
  @override
  Stream<int> watchBalance() async* {
    yield await getBalance();
  }

  @override
  Future<Result<PointsTransaction>> spendPoints({
    required int points,
    required String referenceId,
    required String description,
  }) async => const ResultFailure(InsufficientPointsException());

  @override
  Future<void> refundPoints({
    required int points,
    required String referenceId,
    required String description,
  }) => addPoints(
    points: points,
    source: PointsSource.refund,
    referenceId: referenceId,
    description: description,
  );

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
  Future<int> getTotalEarned() => getLifetimePoints();

  @override
  Future<void> awardQuizBonus({required String referenceId}) => addPoints(
    points: 10,
    source: PointsSource.bonus,
    description: 'Bonus kuis',
    referenceId: referenceId,
  );
}
