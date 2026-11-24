enum PointsTransactionDirection { earned, redeemed }

enum PointsSource {
  smartScan,
  pickup,
  directDeposit,
  redemption,
  systemAdjustment,
}

extension PointsSourceLabel on PointsSource {
  String get label => switch (this) {
    PointsSource.smartScan => 'Smart Scan',
    PointsSource.pickup => 'Penjemputan',
    PointsSource.directDeposit => 'Setor langsung',
    PointsSource.redemption => 'Penukaran',
    PointsSource.systemAdjustment => 'Penyesuaian saldo',
  };
}

class PointsTransaction {
  const PointsTransaction({
    required this.id,
    required this.points,
    required this.direction,
    required this.source,
    required this.description,
    required this.createdAt,
    this.referenceId,
  });

  final String id;
  final int points;
  final PointsTransactionDirection direction;
  final PointsSource source;
  final String description;
  final DateTime createdAt;
  final String? referenceId;

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    final direction = PointsTransactionDirection.values
        .where((value) => value.name == json['direction'])
        .firstOrNull;
    final source = PointsSource.values
        .where((value) => value.name == json['source'])
        .firstOrNull;
    if (json['id'] is! String ||
        json['points'] is! int ||
        direction == null ||
        source == null ||
        json['description'] is! String ||
        json['createdAt'] is! String) {
      throw const FormatException('Data transaksi poin tidak valid.');
    }

    return PointsTransaction(
      id: json['id'] as String,
      points: json['points'] as int,
      direction: direction,
      source: source,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      referenceId: json['referenceId'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'points': points,
    'direction': direction.name,
    'source': source.name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'referenceId': referenceId,
  };
}
