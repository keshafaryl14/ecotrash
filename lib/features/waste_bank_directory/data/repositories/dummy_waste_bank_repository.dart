import 'dart:math' as math;

import 'package:ecotrash/features/waste_bank_directory/domain/entities/geo_point.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/repositories/waste_bank_repository.dart';

class DummyWasteBankRepository implements WasteBankRepository {
  static const _entries = [
    _DummyBank(
      name: 'Bank Sampah Mitra Hijau 01',
      eastMeters: 320,
      northMeters: 180,
      address: 'Lokasi demo di sekitar titik pengguna · arah timur laut',
      acceptedWasteTypes: ['Plastik', 'Kertas', 'Logam'],
      contact: '+6281234500101',
      rating: 4.8,
      openingHours: 'Senin-Sabtu, 08.00-16.00 WIB',
    ),
    _DummyBank(
      name: 'Bank Sampah Berseri 02',
      eastMeters: -650,
      northMeters: 100,
      address: 'Lokasi demo di sekitar titik pengguna · arah barat',
      acceptedWasteTypes: ['Plastik', 'Kaca'],
      contact: '+6281234500102',
      rating: 4.6,
      openingHours: 'Senin-Jumat, 09.00-15.00 WIB',
    ),
    _DummyBank(
      name: 'Rumah Daur Ulang Lestari 03',
      eastMeters: 210,
      northMeters: -780,
      address: 'Lokasi demo di sekitar titik pengguna · arah tenggara',
      acceptedWasteTypes: ['Kertas', 'Kardus', 'Logam'],
      contact: '+6281234500103',
      rating: 4.7,
      openingHours: 'Setiap hari, 08.00-17.00 WIB',
    ),
    _DummyBank(
      name: 'Bank Sampah Sejahtera 04',
      eastMeters: -950,
      northMeters: -250,
      address: 'Lokasi demo di sekitar titik pengguna · arah barat daya',
      acceptedWasteTypes: ['Plastik', 'Kertas', 'Elektronik'],
      contact: '+6281234500104',
      rating: 4.5,
      openingHours: 'Senin-Sabtu, 08.00-15.00 WIB',
    ),
    _DummyBank(
      name: 'Pusat Pilah Mandiri 05',
      eastMeters: 1200,
      northMeters: 330,
      address: 'Lokasi demo di sekitar titik pengguna · arah timur',
      acceptedWasteTypes: ['Kaca', 'Logam', 'Elektronik'],
      contact: '+6281234500105',
      rating: 4.9,
      openingHours: 'Senin-Jumat, 08.30-16.00 WIB',
    ),
    _DummyBank(
      name: 'Bank Sampah Karya Warga 06',
      eastMeters: -300,
      northMeters: 1400,
      address: 'Lokasi demo di sekitar titik pengguna · arah utara',
      acceptedWasteTypes: ['Plastik', 'Kertas', 'Kardus'],
      contact: '+6281234500106',
      rating: 4.4,
      openingHours: 'Selasa-Minggu, 09.00-16.00 WIB',
    ),
    _DummyBank(
      name: 'Daur Ulang Cerdas 07',
      eastMeters: 900,
      northMeters: -1250,
      address: 'Lokasi demo di sekitar titik pengguna · arah tenggara',
      acceptedWasteTypes: ['Plastik', 'Kaca', 'Elektronik'],
      contact: '+6281234500107',
      rating: 4.7,
      openingHours: 'Senin-Sabtu, 08.00-16.30 WIB',
    ),
    _DummyBank(
      name: 'Bank Sampah Tunas Bumi 08',
      eastMeters: -1600,
      northMeters: 800,
      address: 'Lokasi demo di sekitar titik pengguna · arah barat laut',
      acceptedWasteTypes: ['Kertas', 'Logam'],
      contact: '+6281234500108',
      rating: 4.3,
      openingHours: 'Senin-Jumat, 08.00-14.00 WIB',
    ),
    _DummyBank(
      name: 'Sentra Sampah Produktif 09',
      eastMeters: 1750,
      northMeters: -700,
      address: 'Lokasi demo di sekitar titik pengguna · arah tenggara',
      acceptedWasteTypes: ['Plastik', 'Kardus', 'Logam'],
      contact: '+6281234500109',
      rating: 4.6,
      openingHours: 'Setiap hari, 09.00-17.00 WIB',
    ),
    _DummyBank(
      name: 'Bank Sampah Harmoni 10',
      eastMeters: -1100,
      northMeters: -1400,
      address: 'Lokasi demo di sekitar titik pengguna · arah barat daya',
      acceptedWasteTypes: ['Plastik', 'Kertas', 'Kaca', 'Elektronik'],
      contact: '+6281234500110',
      rating: 4.8,
      openingHours: 'Senin-Sabtu, 08.00-16.00 WIB',
    ),
  ];

  @override
  Future<List<WasteBank>> getNearbyWasteBanks(GeoPoint center) async {
    final latitudeScale = 1 / 111320;
    final longitudeScale =
        1 /
        (111320 *
            math.cos(center.latitude * math.pi / 180).abs().clamp(0.01, 1));

    return [
      for (var index = 0; index < _entries.length; index++)
        _entries[index].toWasteBank(
          index: index,
          center: center,
          latitudeScale: latitudeScale,
          longitudeScale: longitudeScale,
        ),
    ];
  }
}

class _DummyBank {
  const _DummyBank({
    required this.name,
    required this.eastMeters,
    required this.northMeters,
    required this.address,
    required this.acceptedWasteTypes,
    required this.contact,
    required this.rating,
    required this.openingHours,
  });

  final String name;
  final double eastMeters;
  final double northMeters;
  final String address;
  final List<String> acceptedWasteTypes;
  final String contact;
  final double rating;
  final String openingHours;

  WasteBank toWasteBank({
    required int index,
    required GeoPoint center,
    required double latitudeScale,
    required double longitudeScale,
  }) {
    return WasteBank(
      id: 'demo-${index + 1}',
      name: name,
      address: address,
      location: GeoPoint(
        latitude: center.latitude + northMeters * latitudeScale,
        longitude: center.longitude + eastMeters * longitudeScale,
      ),
      openingHours: openingHours,
      acceptedWasteTypes: acceptedWasteTypes,
      contact: contact,
      rating: rating,
    );
  }
}
