import 'dart:typed_data';

import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';
import 'package:ecotrash/features/smart_scan/domain/repositories/waste_classifier.dart';

class MockWasteClassifier implements WasteClassifier {
  MockWasteClassifier({
    this.result = const WasteClassification(
      category: WasteCategory.inorganic,
      confidence: 0.93,
      specificType: 'Botol plastik PET',
      sortingInstructions:
          'Kosongkan botol, bilas jika kotor, lalu pisahkan tutup dan label '
          'sesuai aturan bank sampah.',
      processingInstructions:
          'Setor dalam keadaan kering agar dapat dicacah dan diolah menjadi '
          'bahan plastik daur ulang.',
      hasEconomicValue: true,
    ),
  });

  final WasteClassification result;

  @override
  Future<WasteClassification> classify(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      throw const WasteClassifierException(
        'Foto kosong dan tidak dapat dipindai.',
      );
    }
    return result;
  }
}
