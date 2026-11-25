abstract final class RewardsConfig {
  static const pointsPerKgByWasteType = <String, int>{
    'plastic': 10,
    'paperCardboard': 6,
    'glass': 8,
    'metal': 15,
    'smallElectronics': 20,
  };

  static const noPointsReasons = <String, String>{
    'organic': 'Sampah organik diarahkan untuk kompos, bukan setoran poin.',
    'hazardous': 'Sampah B3 perlu ditangani khusus demi keselamatan.',
  };

  static const firstPickupBonus = 20;
  static const perfectQuizBonus = 10;
  static const bulkWeightBonusThresholdKg = 10.0;
  static const bulkWeightBonusPercent = 10;
  static const levels = <(String, int)>[
    ('Pemula', 0),
    ('Pejuang Hijau', 500),
    ('Pahlawan Bumi', 2000),
  ];
  static const maxRedemptionsPerDay = 3;
  static const voucherValidityDays = 30;
  static const cancellationWindow = Duration(hours: 24);
  static const expiryReminderDays = 3;

  static const co2KgSavedPerKg = <String, double>{
    'plastic': 1.5,
    'paperCardboard': 0.9,
    'glass': 0.3,
    'metal': 4.0,
    'smallElectronics': 2.0,
  };

  static int pointsForWeights(Map<String, double> weightsKg) {
    var base = 0;
    for (final entry in weightsKg.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'Berat tidak boleh negatif',
        );
      }
      final rate = pointsPerKgByWasteType[entry.key] ?? 0;
      base += (entry.value * rate).round();
    }
    return base;
  }

  static int calculatePickupPoints(
    Map<String, double> weightsKg, {
    required bool isFirstPickup,
  }) {
    final base = pointsForWeights(weightsKg);
    final totalWeight = weightsKg.values.fold<double>(0, (a, b) => a + b);
    final bulkBonus = totalWeight >= bulkWeightBonusThresholdKg
        ? (base * bulkWeightBonusPercent / 100).round()
        : 0;
    return base + bulkBonus + (isFirstPickup ? firstPickupBonus : 0);
  }

  static double co2SavedKg(Map<String, double> weightsKg) =>
      weightsKg.entries.fold(
        0,
        (total, entry) =>
            total + entry.value * (co2KgSavedPerKg[entry.key] ?? 0),
      );
}
