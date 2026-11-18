import 'dart:typed_data';

import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';

abstract interface class WasteClassifier {
  Future<WasteClassification> classify(Uint8List imageBytes);
}

class WasteClassifierException implements Exception {
  const WasteClassifierException(this.message);

  final String message;

  @override
  String toString() => message;
}
