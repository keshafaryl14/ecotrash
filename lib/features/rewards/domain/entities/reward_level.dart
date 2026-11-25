import 'package:ecotrash/features/rewards/domain/rewards_config.dart';

class RewardLevel {
  const RewardLevel({
    required this.name,
    required this.minimumPoints,
    required this.badge,
    required this.benefit,
    this.nextLevelMinimum,
  });

  final String name;
  final int minimumPoints;
  final String badge;
  final String benefit;
  final int? nextLevelMinimum;

  static final levels = [
    for (var index = 0; index < RewardsConfig.levels.length; index++)
      RewardLevel(
        name: RewardsConfig.levels[index].$1,
        minimumPoints: RewardsConfig.levels[index].$2,
        badge: switch (index) {
          0 => '🌱',
          1 => '🌿',
          _ => '🌍',
        },
        benefit: switch (index) {
          0 => 'Mulai langkah baik untuk lingkungan.',
          1 => 'Lencana Pejuang Hijau dan akses reward pilihan.',
          _ => 'Lencana Pahlawan Bumi dan promo mitra eksklusif.',
        },
        nextLevelMinimum: index + 1 < RewardsConfig.levels.length
            ? RewardsConfig.levels[index + 1].$2
            : null,
      ),
  ];

  static RewardLevel forTotalPoints(int totalPoints) {
    if (totalPoints < 0) {
      throw ArgumentError.value(
        totalPoints,
        'totalPoints',
        'Tidak boleh negatif',
      );
    }

    return levels.lastWhere((level) => totalPoints >= level.minimumPoints);
  }

  double progressFor(int totalPoints) {
    final next = nextLevelMinimum;
    if (next == null) {
      return 1;
    }
    return ((totalPoints - minimumPoints) / (next - minimumPoints))
        .clamp(0, 1)
        .toDouble();
  }

  int? pointsToNextLevel(int totalPoints) {
    final next = nextLevelMinimum;
    return next == null ? null : next - totalPoints;
  }
}

typedef UserLevel = RewardLevel;
