import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/services/pickup_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires at least 3 kg across selected waste types', () {
    expect(
      PickupValidation.validateWasteWeights({
        PickupWasteType.plastic: 1.5,
        PickupWasteType.glass: 1,
      }),
      contains('minimal 3 kg'),
    );
    expect(
      PickupValidation.validateWasteWeights({
        PickupWasteType.plastic: 2,
        PickupWasteType.paperCardboard: 1,
      }),
      isNull,
    );
  });

  test('rejects invalid weights and incomplete addresses', () {
    expect(
      PickupValidation.validateWasteWeights({PickupWasteType.plastic: 0}),
      contains('lebih dari 0 kg'),
    );
    expect(PickupValidation.validateAddress(''), contains('wajib diisi'));
    expect(
      PickupValidation.validateAddress('Jl. A'),
      contains('lebih lengkap'),
    );
  });

  test('rejects past pickup dates but accepts today', () {
    final today = DateTime(2026, 11, 19, 9);

    expect(
      PickupValidation.validatePickupDate(DateTime(2026, 11, 18), today: today),
      contains('masa lalu'),
    );
    expect(
      PickupValidation.validatePickupDate(DateTime(2026, 11, 19), today: today),
      isNull,
    );
  });

  test('estimates ten points per kilogram', () {
    expect(estimatePickupPoints(3), 30);
    expect(estimatePickupPoints(3.55), 36);
  });
}
