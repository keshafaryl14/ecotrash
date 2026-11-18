import 'dart:typed_data';

import 'package:ecotrash/features/smart_scan/data/classifiers/mock_waste_classifier.dart';
import 'package:ecotrash/features/smart_scan/domain/repositories/waste_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns a plausible plastic bottle classification', () async {
    final result = await MockWasteClassifier().classify(
      Uint8List.fromList([1]),
    );

    expect(result.specificType, 'Botol plastik PET');
    expect(result.confidence, greaterThan(0.6));
    expect(result.hasEconomicValue, isTrue);
  });

  test('rejects empty image data', () {
    expect(
      () => MockWasteClassifier().classify(Uint8List(0)),
      throwsA(isA<WasteClassifierException>()),
    );
  });
}
