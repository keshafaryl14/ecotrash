abstract final class PointsConfiguration {
  static const pointsPerKilogramByWasteType = <String, int>{
    'plastic': 15,
    'paperCardboard': 10,
    'glass': 8,
    'metal': 20,
    'smallElectronics': 25,
  };

  static const fallbackPointsPerKilogram = 10;

  static int pointsForWeights(Map<String, double> weightsKg) {
    return weightsKg.entries.fold(0, (total, entry) {
      final rate =
          pointsPerKilogramByWasteType[entry.key] ?? fallbackPointsPerKilogram;
      return total + (entry.value * rate).round();
    });
  }
}
