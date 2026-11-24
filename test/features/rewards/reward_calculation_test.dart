import 'package:ecotrash/core/constants/points_configuration.dart';
import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates pickup points using each waste type rate', () {
    expect(
      estimatePickupPointsForWeights({
        PickupWasteType.plastic: 1,
        PickupWasteType.paperCardboard: 2,
      }),
      35,
    );
    expect(
      PointsConfiguration.pointsPerKilogramByWasteType['smallElectronics'],
      25,
    );
  });

  test('assigns levels and progress from lifetime points', () {
    final beginner = RewardLevel.forTotalPoints(0);
    expect(beginner.name, 'Pemula');
    expect(beginner.progressFor(250), 0.5);
    expect(beginner.pointsToNextLevel(250), 250);

    final greenWarrior = RewardLevel.forTotalPoints(500);
    expect(greenWarrior.name, 'Pejuang Hijau');
    expect(greenWarrior.progressFor(1250), 0.5);

    final earthHero = RewardLevel.forTotalPoints(2000);
    expect(earthHero.name, 'Pahlawan Bumi');
    expect(earthHero.progressFor(5000), 1);
    expect(earthHero.pointsToNextLevel(5000), isNull);
  });
}
