import 'dart:typed_data';

import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';
import 'package:ecotrash/features/smart_scan/domain/repositories/waste_classifier.dart';

/// TFLite integration point; the mock classifier remains the default for now.
class TfliteWasteClassifier implements WasteClassifier {
  @override
  Future<WasteClassification> classify(Uint8List imageBytes) async {
    // TODO: Add tflite_flutter and assets/models/waste_classifier.tflite.
    // Preprocess images to the model's RGB input size, run inference, then map
    // the highest-scoring label to a WasteClassification.
    throw const WasteClassifierException(
      'Model klasifikasi belum dipasang. Gunakan MockWasteClassifier dahulu.',
    );
  }
}
