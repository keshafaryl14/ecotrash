import 'package:ecotrash/features/smart_scan/data/classifiers/mock_waste_classifier.dart';
import 'package:ecotrash/features/smart_scan/data/repositories/shared_preferences_scan_history_repository.dart';
import 'package:ecotrash/features/smart_scan/domain/entities/scan_record.dart';
import 'package:ecotrash/features/smart_scan/domain/repositories/scan_history_repository.dart';
import 'package:ecotrash/features/smart_scan/domain/repositories/waste_classifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wasteClassifierProvider = Provider<WasteClassifier>((ref) {
  return MockWasteClassifier();
});

final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>((ref) {
  return SharedPreferencesScanHistoryRepository();
});

final scanHistoryProvider = FutureProvider<List<ScanRecord>>((ref) {
  return ref.watch(scanHistoryRepositoryProvider).loadHistory();
});
