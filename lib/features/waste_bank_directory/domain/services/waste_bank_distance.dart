import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:geolocator/geolocator.dart';

double distanceBetweenMeters(GeoPoint first, GeoPoint second) {
  return Geolocator.distanceBetween(
    first.latitude,
    first.longitude,
    second.latitude,
    second.longitude,
  );
}

List<WasteBank> filterAndSortWasteBanks({
  required List<WasteBank> banks,
  required GeoPoint center,
  String query = '',
  String wasteType = 'Semua',
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = banks.where((bank) {
    final matchesName =
        normalizedQuery.isEmpty ||
        bank.name.toLowerCase().contains(normalizedQuery);
    final matchesType =
        wasteType == 'Semua' ||
        bank.acceptedWasteTypes.any(
          (type) => type.toLowerCase() == wasteType.toLowerCase(),
        );
    return matchesName && matchesType;
  }).toList();

  filtered.sort(
    (first, second) => distanceBetweenMeters(
      center,
      first.location,
    ).compareTo(distanceBetweenMeters(center, second.location)),
  );
  return filtered;
}
