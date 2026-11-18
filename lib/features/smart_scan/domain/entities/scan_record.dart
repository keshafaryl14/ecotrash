import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';

class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.scannedAt,
    required this.category,
    required this.confidence,
    required this.specificType,
    required this.hasEconomicValue,
  });

  final String id;
  final DateTime scannedAt;
  final WasteCategory category;
  final double confidence;
  final String specificType;
  final bool hasEconomicValue;

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'];
    final category = WasteCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => throw const FormatException('Kategori scan tidak dikenal.'),
    );
    final confidenceValue = json['confidence'];
    final dateValue = json['scannedAt'];
    if (confidenceValue is! num ||
        dateValue is! String ||
        json['id'] is! String ||
        json['specificType'] is! String ||
        json['hasEconomicValue'] is! bool) {
      throw const FormatException('Data riwayat scan tidak lengkap.');
    }

    final confidence = confidenceValue.toDouble();
    if (confidence < 0 || confidence > 1) {
      throw const FormatException('Tingkat keyakinan scan tidak valid.');
    }

    return ScanRecord(
      id: json['id'] as String,
      scannedAt: DateTime.parse(dateValue),
      category: category,
      confidence: confidence,
      specificType: json['specificType'] as String,
      hasEconomicValue: json['hasEconomicValue'] as bool,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'scannedAt': scannedAt.toIso8601String(),
    'category': category.name,
    'confidence': confidence,
    'specificType': specificType,
    'hasEconomicValue': hasEconomicValue,
  };
}
