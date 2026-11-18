import 'dart:convert';

import 'package:ecotrash/features/smart_scan/domain/entities/scan_record.dart';
import 'package:ecotrash/features/smart_scan/domain/repositories/scan_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesScanHistoryRepository implements ScanHistoryRepository {
  static const _historyKey = 'smart_scan_history';

  @override
  Future<List<ScanRecord>> loadHistory() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_historyKey);
      if (encoded == null || encoded.isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        throw const FormatException('Riwayat scan bukan berupa daftar.');
      }
      return decoded.map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Entri riwayat scan tidak valid.');
        }
        return ScanRecord.fromJson(entry);
      }).toList();
    } on ScanHistoryException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const ScanHistoryException('Riwayat scan tidak dapat dibaca.'),
        stackTrace,
      );
    }
  }

  @override
  Future<void> save(ScanRecord record) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final history = List<ScanRecord>.of(await loadHistory());
      history.insert(0, record);
      final saved = await preferences.setString(
        _historyKey,
        jsonEncode(history.map((entry) => entry.toJson()).toList()),
      );
      if (!saved) {
        throw const ScanHistoryException('Riwayat scan tidak dapat disimpan.');
      }
    } on ScanHistoryException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const ScanHistoryException('Riwayat scan tidak dapat disimpan.'),
        stackTrace,
      );
    }
  }
}
