import 'package:ecotrash/features/waste_bank_directory/data/repositories/dummy_waste_bank_repository.dart';
import 'package:ecotrash/features/waste_bank_directory/data/services/geolocator_location_service.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/repositories/waste_bank_repository.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WasteBankDirectoryData {
  const WasteBankDirectoryData({
    required this.userLocation,
    required this.banks,
  });

  final GeoPoint userLocation;
  final List<WasteBank> banks;
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});

final wasteBankRepositoryProvider = Provider<WasteBankRepository>((ref) {
  return DummyWasteBankRepository();
});

final wasteBankDirectoryProvider = FutureProvider<WasteBankDirectoryData>((
  ref,
) async {
  final location = await ref
      .watch(locationServiceProvider)
      .getCurrentLocation();
  final banks = await ref
      .watch(wasteBankRepositoryProvider)
      .getNearbyWasteBanks(location);
  return WasteBankDirectoryData(userLocation: location, banks: banks);
});
