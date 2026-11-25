import 'package:ecotrash/core/constants/points_configuration.dart';
import 'package:ecotrash/features/rewards/domain/rewards_config.dart';

enum PickupWasteType { plastic, paperCardboard, glass, metal, smallElectronics }

extension PickupWasteTypeLabel on PickupWasteType {
  String get label => switch (this) {
    PickupWasteType.plastic => 'Plastik',
    PickupWasteType.paperCardboard => 'Kertas / kardus',
    PickupWasteType.glass => 'Kaca',
    PickupWasteType.metal => 'Logam',
    PickupWasteType.smallElectronics => 'Elektronik kecil',
  };
}

enum PickupOrderStatus {
  waitingConfirmation,
  confirmed,
  courierEnRoute,
  completed,
  cancelled,
}

extension PickupOrderStatusLabel on PickupOrderStatus {
  String get label => switch (this) {
    PickupOrderStatus.waitingConfirmation => 'Menunggu konfirmasi',
    PickupOrderStatus.confirmed => 'Dikonfirmasi',
    PickupOrderStatus.courierEnRoute => 'Kurir menuju lokasi',
    PickupOrderStatus.completed => 'Selesai',
    PickupOrderStatus.cancelled => 'Dibatalkan',
  };

  bool get isActive =>
      this == PickupOrderStatus.waitingConfirmation ||
      this == PickupOrderStatus.confirmed ||
      this == PickupOrderStatus.courierEnRoute;

  bool get canBeCancelled =>
      this == PickupOrderStatus.waitingConfirmation ||
      this == PickupOrderStatus.confirmed;
}

class PickupOrder {
  const PickupOrder({
    required this.id,
    required this.wasteWeightsKg,
    required this.address,
    required this.courierNote,
    required this.pickupAt,
    required this.timeSlot,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final Map<PickupWasteType, double> wasteWeightsKg;
  final String address;
  final String courierNote;
  final DateTime pickupAt;
  final String timeSlot;
  final DateTime createdAt;
  final PickupOrderStatus status;

  double get totalWeightKg =>
      wasteWeightsKg.values.fold(0, (total, weight) => total + weight);

  int get estimatedPoints => estimatePickupPointsForWeights(wasteWeightsKg);

  PickupOrder copyWith({PickupOrderStatus? status}) {
    return PickupOrder(
      id: id,
      wasteWeightsKg: wasteWeightsKg,
      address: address,
      courierNote: courierNote,
      pickupAt: pickupAt,
      timeSlot: timeSlot,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  factory PickupOrder.fromJson(Map<String, dynamic> json) {
    final rawWeights = json['wasteWeightsKg'];
    final weights = <PickupWasteType, double>{};
    if (rawWeights is! Map) {
      throw const FormatException('Rincian berat pesanan tidak valid.');
    }
    for (final entry in rawWeights.entries) {
      final type = PickupWasteType.values.where(
        (value) => value.name == entry.key,
      );
      if (type.isEmpty || entry.value is! num) {
        throw const FormatException('Jenis atau berat sampah tidak valid.');
      }
      weights[type.first] = (entry.value as num).toDouble();
    }

    final status = PickupOrderStatus.values.where(
      (value) => value.name == json['status'],
    );
    if (status.isEmpty ||
        json['id'] is! String ||
        json['address'] is! String ||
        json['courierNote'] is! String ||
        json['timeSlot'] is! String ||
        json['pickupAt'] is! String ||
        json['createdAt'] is! String) {
      throw const FormatException('Data pesanan penjemputan tidak lengkap.');
    }

    return PickupOrder(
      id: json['id'] as String,
      wasteWeightsKg: weights,
      address: json['address'] as String,
      courierNote: json['courierNote'] as String,
      pickupAt: DateTime.parse(json['pickupAt'] as String),
      timeSlot: json['timeSlot'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: status.first,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'wasteWeightsKg': {
      for (final entry in wasteWeightsKg.entries) entry.key.name: entry.value,
    },
    'address': address,
    'courierNote': courierNote,
    'pickupAt': pickupAt.toIso8601String(),
    'timeSlot': timeSlot,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };
}

int estimatePickupPointsForWeights(Map<PickupWasteType, double> weightsKg) {
  final weights = {
    for (final entry in weightsKg.entries) entry.key.name: entry.value,
  };
  final base = PointsConfiguration.pointsForWeights(weights);
  final totalWeight = weights.values.fold<double>(0, (a, b) => a + b);
  return base +
      (totalWeight >= RewardsConfig.bulkWeightBonusThresholdKg
          ? (base * RewardsConfig.bulkWeightBonusPercent / 100).round()
          : 0);
}

int estimatePickupPoints(double totalWeightKg) =>
    (totalWeightKg * PointsConfiguration.fallbackPointsPerKilogram).round();
