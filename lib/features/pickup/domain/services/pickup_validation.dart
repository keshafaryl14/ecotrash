import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';

abstract final class PickupValidation {
  static const minimumWeightKg = 3.0;

  static String? validateWasteWeights(
    Map<PickupWasteType, double> wasteWeightsKg,
  ) {
    if (wasteWeightsKg.isEmpty) {
      return 'Pilih setidaknya satu jenis sampah.';
    }
    if (wasteWeightsKg.values.any(
      (weight) => !weight.isFinite || weight <= 0,
    )) {
      return 'Berat setiap jenis sampah harus lebih dari 0 kg.';
    }
    final total = wasteWeightsKg.values.fold<double>(
      0,
      (sum, weight) => sum + weight,
    );
    if (total < minimumWeightKg) {
      return 'Total sampah minimal 3 kg (saat ini ${total.toStringAsFixed(1)} kg).';
    }
    return null;
  }

  static String? validateAddress(String address) {
    if (address.trim().isEmpty) {
      return 'Alamat penjemputan wajib diisi.';
    }
    if (address.trim().length < 8) {
      return 'Masukkan alamat penjemputan yang lebih lengkap.';
    }
    return null;
  }

  static String? validatePickupDate(DateTime? date, {DateTime? today}) {
    if (date == null) {
      return 'Pilih tanggal penjemputan.';
    }
    final now = today ?? DateTime.now();
    final selectedDay = DateTime(date.year, date.month, date.day);
    final currentDay = DateTime(now.year, now.month, now.day);
    if (selectedDay.isBefore(currentDay)) {
      return 'Tanggal penjemputan tidak boleh di masa lalu.';
    }
    return null;
  }
}
