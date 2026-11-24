class RewardLevel {
  const RewardLevel({
    required this.name,
    required this.minimumPoints,
    this.nextLevelMinimum,
  });

  final String name;
  final int minimumPoints;
  final int? nextLevelMinimum;

  static const levels = [
    RewardLevel(name: 'Pemula', minimumPoints: 0, nextLevelMinimum: 500),
    RewardLevel(
      name: 'Pejuang Hijau',
      minimumPoints: 500,
      nextLevelMinimum: 2000,
    ),
    RewardLevel(name: 'Pahlawan Bumi', minimumPoints: 2000),
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
