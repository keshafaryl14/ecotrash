enum WasteCategory { organic, inorganic, hazardous }

class WasteClassification {
  const WasteClassification({
    required this.category,
    required this.confidence,
    required this.specificType,
    required this.sortingInstructions,
    required this.processingInstructions,
    required this.hasEconomicValue,
  }) : assert(confidence >= 0 && confidence <= 1);

  final WasteCategory category;
  final double confidence;
  final String specificType;
  final String sortingInstructions;
  final String processingInstructions;
  final bool hasEconomicValue;

  bool get needsRetake => confidence < 0.6;
}
