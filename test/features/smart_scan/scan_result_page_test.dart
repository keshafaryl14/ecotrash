import 'dart:typed_data';

import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';
import 'package:ecotrash/features/smart_scan/presentation/scan_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows classification and guidance when confidence is low', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ScanResultPage(
          args: ScanResultPageArgs(
            imageBytes: Uint8List.fromList([1]),
            classification: const WasteClassification(
              category: WasteCategory.hazardous,
              confidence: 0.42,
              specificType: 'Baterai bekas',
              sortingInstructions: 'Pisahkan dari sampah rumah tangga lainnya.',
              processingInstructions:
                  'Serahkan ke fasilitas pengelola limbah B3.',
              hasEconomicValue: false,
            ),
            historySaved: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('B3'), findsOneWidget);
    expect(find.text('Baterai bekas'), findsOneWidget);
    expect(find.text('Tingkat keyakinan: 42%'), findsOneWidget);
    expect(find.textContaining('Keyakinan masih rendah'), findsOneWidget);
    expect(find.byKey(const Key('scan-result-bank-button')), findsOneWidget);
    expect(find.byKey(const Key('scan-result-pickup-button')), findsOneWidget);
  });

  testWidgets('shows a notice if the scan could not be saved', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ScanResultPage(
          args: ScanResultPageArgs(
            imageBytes: Uint8List.fromList([1]),
            classification: const WasteClassification(
              category: WasteCategory.inorganic,
              confidence: 0.9,
              specificType: 'Kardus',
              sortingInstructions: 'Pastikan kardus kering.',
              processingInstructions: 'Setorkan ke bank sampah.',
              hasEconomicValue: true,
            ),
            historySaved: false,
            historyError: 'Riwayat scan tidak dapat disimpan.',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Riwayat scan tidak dapat disimpan.'), findsOneWidget);
  });
}
