import 'package:ecotrash/features/smart_scan/data/repositories/shared_preferences_scan_history_repository.dart';
import 'package:ecotrash/features/smart_scan/domain/entities/scan_record.dart';
import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and reloads a scan record', () async {
    final repository = SharedPreferencesScanHistoryRepository();
    final record = ScanRecord(
      id: 'scan-1',
      scannedAt: DateTime.utc(2026, 5, 1, 10),
      category: WasteCategory.inorganic,
      confidence: 0.93,
      specificType: 'Botol plastik PET',
      hasEconomicValue: true,
    );

    await repository.save(record);

    final loaded = await repository.loadHistory();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, record.id);
    expect(loaded.single.specificType, record.specificType);
    expect(loaded.single.scannedAt, record.scannedAt);
  });
}
