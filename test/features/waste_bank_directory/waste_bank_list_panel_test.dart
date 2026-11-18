import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:ecotrash/features/waste_bank_directory/presentation/waste_bank_list_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filters banks by name and accepted waste type', (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WasteBankListPanel(
            banks: [
              _bank(
                id: 'plastic',
                name: 'Mitra Hijau',
                acceptedWasteTypes: const ['Plastik'],
                latitude: 0.001,
              ),
              _bank(
                id: 'paper',
                name: 'Berseri',
                acceptedWasteTypes: const ['Kertas'],
                latitude: 0.002,
              ),
              _bank(
                id: 'both',
                name: 'Mitra Berseri',
                acceptedWasteTypes: const ['Plastik', 'Kertas'],
                latitude: 0.003,
              ),
            ],
            center: const GeoPoint(latitude: 0, longitude: 0),
            onBankSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mitra Hijau'), findsOneWidget);
    expect(find.text('Berseri'), findsOneWidget);
    expect(find.text('Mitra Berseri'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('waste-bank-search')), 'hijau');
    await tester.pumpAndSettle();
    expect(find.text('Mitra Hijau'), findsOneWidget);
    expect(find.text('Berseri'), findsNothing);
    expect(find.text('Mitra Berseri'), findsNothing);

    await tester.enterText(find.byKey(const Key('waste-bank-search')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plastik').last);
    await tester.pumpAndSettle();

    expect(find.text('Mitra Hijau'), findsOneWidget);
    expect(find.text('Mitra Berseri'), findsOneWidget);
    expect(find.text('Berseri'), findsNothing);
  });
}

WasteBank _bank({
  required String id,
  required String name,
  required List<String> acceptedWasteTypes,
  required double latitude,
}) {
  return WasteBank(
    id: id,
    name: name,
    address: 'Lokasi demo',
    location: GeoPoint(latitude: latitude, longitude: 0),
    openingHours: 'Senin-Sabtu, 08.00-16.00 WIB',
    acceptedWasteTypes: acceptedWasteTypes,
    contact: '+6281234567890',
    rating: 4.5,
  );
}
