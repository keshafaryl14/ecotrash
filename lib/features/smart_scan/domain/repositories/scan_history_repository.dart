import 'package:ecotrash/features/smart_scan/domain/entities/scan_record.dart';

abstract interface class ScanHistoryRepository {
  Future<List<ScanRecord>> loadHistory();

  Future<void> save(ScanRecord record);
}

class ScanHistoryException implements Exception {
  const ScanHistoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
