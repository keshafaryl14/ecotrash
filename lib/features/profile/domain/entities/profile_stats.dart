class ProfileStats {
  const ProfileStats({
    required this.totalWeightKg,
    required this.totalPoints,
    required this.completedPickups,
    this.co2SavedKg = 0,
  });

  final double totalWeightKg;
  final int totalPoints;
  final int completedPickups;
  final double co2SavedKg;
}
