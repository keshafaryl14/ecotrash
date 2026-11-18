import 'package:ecotrash/features/waste_bank_directory/data/repositories/dummy_waste_bank_repository.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/services/waste_bank_distance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const center = GeoPoint(latitude: 0, longitude: 0);

  test('calculates distance in meters between coordinates', () {
    const nearby = GeoPoint(latitude: 0.001, longitude: 0);

    final distance = distanceBetweenMeters(center, nearby);

    expect(distance, inInclusiveRange(100, 120));
  });

  test('sorts banks from closest to farthest', () {
    final banks = [
      _bank(id: 'far', latitude: 0.01),
      _bank(id: 'near', latitude: 0.001),
      _bank(id: 'middle', latitude: 0.005),
    ];

    final sorted = filterAndSortWasteBanks(banks: banks, center: center);

    expect(sorted.map((bank) => bank.id), ['near', 'middle', 'far']);
  });

  test('provides at least ten demo banks near the supplied location', () async {
    final banks = await DummyWasteBankRepository().getNearbyWasteBanks(
      const GeoPoint(latitude: -6.2, longitude: 106.8),
    );

    expect(banks.length, greaterThanOrEqualTo(10));
    expect(banks.every((bank) => bank.id.startsWith('demo-')), isTrue);
    expect(
      banks.every(
        (bank) =>
            distanceBetweenMeters(
              const GeoPoint(latitude: -6.2, longitude: 106.8),
              bank.location,
            ) <
            2500,
      ),
      isTrue,
    );
  });
}

WasteBank _bank({required String id, required double latitude}) {
  return WasteBank(
    id: id,
    name: 'Bank $id',
    address: 'Alamat $id',
    location: GeoPoint(latitude: latitude, longitude: 0),
    openingHours: '08.00-16.00 WIB',
    acceptedWasteTypes: const ['Plastik'],
    contact: '+6281234567890',
    rating: 4.5,
  );
}
