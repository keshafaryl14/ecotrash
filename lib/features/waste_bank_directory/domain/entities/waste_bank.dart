import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';

class WasteBank {
  const WasteBank({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.openingHours,
    required this.acceptedWasteTypes,
    required this.contact,
    required this.rating,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final String openingHours;
  final List<String> acceptedWasteTypes;
  final String contact;
  final double rating;
  final String? photoUrl;
}
