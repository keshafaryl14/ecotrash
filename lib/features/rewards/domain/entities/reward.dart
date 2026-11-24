enum RewardCategory { ewallet, ecoVoucher }

class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.category,
    required this.validityDays,
    this.amountRupiah,
  });

  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final RewardCategory category;
  final int validityDays;
  final int? amountRupiah;

  static const catalog = [
    Reward(
      id: 'ewallet-10000',
      title: 'Saldo e-wallet Rp10.000',
      description: 'Voucher saldo e-wallet demo',
      pointsCost: 1000,
      category: RewardCategory.ewallet,
      validityDays: 30,
      amountRupiah: 10000,
    ),
    Reward(
      id: 'ewallet-25000',
      title: 'Saldo e-wallet Rp25.000',
      description: 'Voucher saldo e-wallet demo',
      pointsCost: 2500,
      category: RewardCategory.ewallet,
      validityDays: 30,
      amountRupiah: 25000,
    ),
    Reward(
      id: 'ewallet-50000',
      title: 'Saldo e-wallet Rp50.000',
      description: 'Voucher saldo e-wallet demo',
      pointsCost: 5000,
      category: RewardCategory.ewallet,
      validityDays: 30,
      amountRupiah: 50000,
    ),
    Reward(
      id: 'eco-10-percent',
      title: 'Diskon 10% produk ramah lingkungan',
      description: 'Berlaku untuk pembelian produk pilihan.',
      pointsCost: 500,
      category: RewardCategory.ecoVoucher,
      validityDays: 30,
    ),
    Reward(
      id: 'eco-15-percent',
      title: 'Diskon 15% produk ramah lingkungan',
      description: 'Berlaku untuk pembelian minimal Rp50.000.',
      pointsCost: 1000,
      category: RewardCategory.ecoVoucher,
      validityDays: 30,
    ),
    Reward(
      id: 'eco-20-percent',
      title: 'Diskon 20% produk ramah lingkungan',
      description: 'Berlaku untuk pembelian minimal Rp100.000.',
      pointsCost: 1800,
      category: RewardCategory.ecoVoucher,
      validityDays: 30,
    ),
  ];
}

enum RewardVoucherStatus { active, used, expired }

class RewardVoucher {
  const RewardVoucher({
    required this.id,
    required this.rewardId,
    required this.title,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
  });

  final String id;
  final String rewardId;
  final String title;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;

  RewardVoucherStatus get status => statusAt(DateTime.now());

  RewardVoucherStatus statusAt(DateTime now) {
    if (usedAt != null) {
      return RewardVoucherStatus.used;
    }
    return !now.isBefore(expiresAt)
        ? RewardVoucherStatus.expired
        : RewardVoucherStatus.active;
  }

  RewardVoucher copyWith({DateTime? usedAt}) => RewardVoucher(
    id: id,
    rewardId: rewardId,
    title: title,
    code: code,
    createdAt: createdAt,
    expiresAt: expiresAt,
    usedAt: usedAt ?? this.usedAt,
  );

  factory RewardVoucher.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['rewardId'] is! String ||
        json['title'] is! String ||
        json['code'] is! String ||
        json['createdAt'] is! String ||
        json['expiresAt'] is! String) {
      throw const FormatException('Data voucher tidak valid.');
    }
    return RewardVoucher(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      title: json['title'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      usedAt: json['usedAt'] is String
          ? DateTime.parse(json['usedAt'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'rewardId': rewardId,
    'title': title,
    'code': code,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'usedAt': usedAt?.toIso8601String(),
  };
}
