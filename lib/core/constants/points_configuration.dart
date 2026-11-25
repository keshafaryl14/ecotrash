import 'package:ecotrash/features/rewards/domain/rewards_config.dart';

abstract final class PointsConfiguration {
  static const pointsPerKilogramByWasteType =
      RewardsConfig.pointsPerKgByWasteType;
  static const fallbackPointsPerKilogram = 10;

  static int pointsForWeights(Map<String, double> weightsKg) {
    return RewardsConfig.pointsForWeights(weightsKg);
  }
}
