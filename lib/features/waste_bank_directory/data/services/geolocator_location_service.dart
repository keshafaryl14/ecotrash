import 'dart:async';

import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorLocationService implements LocationService {
  @override
  Future<GeoPoint> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'GPS/lokasi perangkat sedang mati.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailure.permissionPermanentlyDenied,
        'Izin lokasi ditolak permanen. Aktifkan izin dari pengaturan aplikasi.',
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationException(
        LocationFailure.permissionDenied,
        'Izin lokasi diperlukan untuk mencari bank sampah terdekat.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'GPS/lokasi perangkat sedang mati.',
      );
    } on PermissionDeniedException {
      throw const LocationException(
        LocationFailure.permissionDenied,
        'Izin lokasi ditolak. Izinkan akses lokasi lalu coba lagi.',
      );
    } on TimeoutException {
      throw const LocationException(
        LocationFailure.unavailable,
        'Lokasi belum berhasil didapatkan. Coba lagi di area dengan sinyal GPS.',
      );
    }
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
