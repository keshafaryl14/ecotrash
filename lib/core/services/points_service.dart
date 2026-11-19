abstract interface class PointsService {
  Future<void> awardPickupCompletion({
    required String orderId,
    required int points,
  });
}
