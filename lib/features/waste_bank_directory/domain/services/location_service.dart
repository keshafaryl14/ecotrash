import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class LocationException implements Exception {
  const LocationException(this.failure, this.message);

  final LocationFailure failure;
  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationService {
  Future<GeoPoint> getCurrentLocation();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();
}
