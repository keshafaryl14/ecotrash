import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';

abstract interface class WasteBankRepository {
  Future<List<WasteBank>> getNearbyWasteBanks(GeoPoint center);
}
