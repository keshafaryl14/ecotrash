import 'package:ecotrash/features/rewards/domain/rewards_config.dart';

enum RewardCategory {
  ewallet,
  voucherDiskon,
  produkRamahLingkungan,
  ecoVoucher,
}

extension RewardCategoryLabel on RewardCategory {
  String get label => switch (this) {
    RewardCategory.ewallet => 'Saldo E-Wallet',
    RewardCategory.voucherDiskon ||
    RewardCategory.ecoVoucher => 'Voucher Diskon',
    RewardCategory.produkRamahLingkungan => 'Produk Ramah Lingkungan',
  };
}

class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.category,
    this.validityDays = RewardsConfig.voucherValidityDays,
    this.amountRupiah,
    this.value = 0,
    this.image = '',
    this.merchant = 'EcoTrash',
    this.terms = 'Kode hanya dapat digunakan satu kali.',
    this.stock,
    this.active = true,
    this.popularity = 0,
  });

  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final RewardCategory category;
  final int validityDays;
  final int? amountRupiah;
  final int value;
  final String image;
  final String merchant;
  final String terms;
  final int? stock;
  final bool active;
  final int popularity;

  static const catalog = <Reward>[
    Reward(
      id: 'ewallet-10000',
      title: 'Saldo e-wallet Rp10.000',
      description: 'Saldo digital untuk kebutuhan harian.',
      pointsCost: 1000,
      category: RewardCategory.ewallet,
      amountRupiah: 10000,
      value: 10000,
      merchant: 'GoPay, OVO, DANA, ShopeePay, LinkAja',
      popularity: 96,
    ),
    Reward(
      id: 'ewallet-25000',
      title: 'Saldo e-wallet Rp25.000',
      description: 'Saldo digital untuk kebutuhan harian.',
      pointsCost: 2400,
      category: RewardCategory.ewallet,
      amountRupiah: 25000,
      value: 25000,
      merchant: 'GoPay, OVO, DANA, ShopeePay, LinkAja',
      popularity: 82,
    ),
    Reward(
      id: 'ewallet-50000',
      title: 'Saldo e-wallet Rp50.000',
      description: 'Saldo digital untuk kebutuhan harian.',
      pointsCost: 4700,
      category: RewardCategory.ewallet,
      amountRupiah: 50000,
      value: 50000,
      merchant: 'GoPay, OVO, DANA, ShopeePay, LinkAja',
      popularity: 74,
    ),
    Reward(
      id: 'ewallet-100000',
      title: 'Saldo e-wallet Rp100.000',
      description: 'Saldo digital untuk kebutuhan harian.',
      pointsCost: 9000,
      category: RewardCategory.ewallet,
      amountRupiah: 100000,
      value: 100000,
      merchant: 'GoPay, OVO, DANA, ShopeePay, LinkAja',
      popularity: 63,
    ),
    Reward(
      id: 'eco-bag',
      title: 'Voucher tas kain',
      description: 'Potongan harga tas belanja kain pakai ulang.',
      pointsCost: 500,
      category: RewardCategory.voucherDiskon,
      value: 15,
      merchant: 'Bumi Store',
      terms: 'Diskon 15%, minimum belanja Rp30.000.',
      popularity: 91,
    ),
    Reward(
      id: 'eco-bottle',
      title: 'Voucher botol minum',
      description: 'Diskon botol minum pakai ulang.',
      pointsCost: 700,
      category: RewardCategory.voucherDiskon,
      value: 20,
      merchant: 'Tumbuh Living',
      terms: 'Diskon 20% untuk satu botol minum.',
      popularity: 88,
    ),
    Reward(
      id: 'eco-straw',
      title: 'Voucher sedotan stainless',
      description: 'Paket sedotan stainless dan sikat pembersih.',
      pointsCost: 450,
      category: RewardCategory.produkRamahLingkungan,
      value: 1,
      merchant: 'Bumi Store',
      popularity: 69,
    ),
    Reward(
      id: 'eco-soap',
      title: 'Voucher sabun ramah lingkungan',
      description: 'Diskon sabun batang tanpa kemasan plastik.',
      pointsCost: 550,
      category: RewardCategory.voucherDiskon,
      value: 15,
      merchant: 'Alam Sehat',
      popularity: 78,
    ),
    Reward(
      id: 'eco-seeds',
      title: 'Voucher bibit tanaman',
      description: 'Pilih bibit sayur untuk ditanam di rumah.',
      pointsCost: 400,
      category: RewardCategory.produkRamahLingkungan,
      value: 1,
      merchant: 'Kebun Kota',
      popularity: 85,
    ),
    Reward(
      id: 'eco-coffee',
      title: 'Voucher kopi bawa tumbler',
      description: 'Nikmati kopi dengan tumbler pakai ulang.',
      pointsCost: 300,
      category: RewardCategory.voucherDiskon,
      value: 100,
      merchant: 'Kopi Hijau',
      terms: 'Gratis satu minuman ukuran reguler dengan tumbler sendiri.',
      popularity: 93,
    ),
    Reward(
      id: 'eco-lunch',
      title: 'Voucher makan minim sampah',
      description: 'Potongan menu pilihan di merchant mitra.',
      pointsCost: 650,
      category: RewardCategory.voucherDiskon,
      value: 15,
      merchant: 'Warung Lestari',
      terms: 'Diskon 15% untuk menu pilihan. Tidak dapat digabung promo.',
      popularity: 72,
    ),
    Reward(
      id: 'eco-cleaning',
      title: 'Voucher paket bersih alami',
      description: 'Diskon produk pembersih berbahan alami.',
      pointsCost: 800,
      category: RewardCategory.voucherDiskon,
      value: 20,
      merchant: 'Alam Sehat',
      terms: 'Diskon 20% untuk paket produk pembersih.',
      popularity: 58,
      stock: 0,
    ),
  ];

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'pointsCost': pointsCost,
    'category': category.name,
    'validityDays': validityDays,
    'amountRupiah': amountRupiah,
    'value': value,
    'image': image,
    'merchant': merchant,
    'terms': terms,
    'stock': stock,
    'active': active,
    'popularity': popularity,
  };

  factory Reward.fromJson(Map<String, dynamic> json) {
    final category = RewardCategory.values
        .where((item) => item.name == json['category'])
        .firstOrNull;
    if (json['id'] is! String ||
        json['title'] is! String ||
        json['description'] is! String ||
        json['pointsCost'] is! int ||
        category == null ||
        json['validityDays'] is! int) {
      throw const FormatException('Data reward tidak valid.');
    }
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      pointsCost: json['pointsCost'] as int,
      category: category,
      validityDays: json['validityDays'] as int,
      amountRupiah: json['amountRupiah'] as int?,
      value: json['value'] as int? ?? 0,
      image: json['image'] as String? ?? '',
      merchant: json['merchant'] as String? ?? 'EcoTrash',
      terms: json['terms'] as String? ?? '',
      stock: json['stock'] as int?,
      active: json['active'] as bool? ?? true,
      popularity: json['popularity'] as int? ?? 0,
    );
  }
}

typedef RewardItem = Reward;

enum RewardVoucherStatus {
  active,
  processing,
  used,
  expired,
  cancelled,
  failed,
}

enum EwalletPayoutStatus { notApplicable, processing, successful, failed }

class RewardVoucher {
  const RewardVoucher({
    required this.id,
    required this.rewardId,
    required this.title,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.statusOverride,
    this.value = 0,
    this.merchant = 'EcoTrash',
    this.terms = '',
    this.targetPhone,
    this.ewalletProvider,
    this.payoutStatus = EwalletPayoutStatus.notApplicable,
    this.payoutTransactionId,
    this.redemptionReference,
    this.pointsCost = 0,
    this.cancelledAt,
  });

  final String id;
  final String rewardId;
  final String title;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final RewardVoucherStatus? statusOverride;
  final int value;
  final String merchant;
  final String terms;
  final String? targetPhone;
  final String? ewalletProvider;
  final EwalletPayoutStatus payoutStatus;
  final String? payoutTransactionId;
  final String? redemptionReference;
  final int pointsCost;
  final DateTime? cancelledAt;

  RewardVoucherStatus get status => statusAt(DateTime.now());

  RewardVoucherStatus statusAt(DateTime now) {
    if (statusOverride != null &&
        statusOverride != RewardVoucherStatus.active) {
      return statusOverride!;
    }

    if (usedAt != null) {
      return RewardVoucherStatus.used;
    }
    if (payoutStatus == EwalletPayoutStatus.processing) {
      return RewardVoucherStatus.processing;
    }
    return !now.isBefore(expiresAt)
        ? RewardVoucherStatus.expired
        : RewardVoucherStatus.active;
  }

  RewardVoucher copyWith({
    DateTime? usedAt,
    RewardVoucherStatus? statusOverride,
    EwalletPayoutStatus? payoutStatus,
    String? payoutTransactionId,
    DateTime? cancelledAt,
    String? code,
  }) => RewardVoucher(
    id: id,
    rewardId: rewardId,
    title: title,
    code: code ?? this.code,
    createdAt: createdAt,
    expiresAt: expiresAt,
    usedAt: usedAt ?? this.usedAt,
    statusOverride: statusOverride ?? this.statusOverride,
    value: value,
    merchant: merchant,
    terms: terms,
    targetPhone: targetPhone,
    ewalletProvider: ewalletProvider,
    payoutStatus: payoutStatus ?? this.payoutStatus,
    payoutTransactionId: payoutTransactionId ?? this.payoutTransactionId,
    redemptionReference: redemptionReference,
    pointsCost: pointsCost,
    cancelledAt: cancelledAt ?? this.cancelledAt,
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
      usedAt: _date(json['usedAt']),
      statusOverride: _enumValue(RewardVoucherStatus.values, json['status']),
      value: json['value'] as int? ?? 0,
      merchant: json['merchant'] as String? ?? 'EcoTrash',
      terms: json['terms'] as String? ?? '',
      targetPhone: json['targetPhone'] as String?,
      ewalletProvider: json['ewalletProvider'] as String?,
      payoutStatus:
          _enumValue(EwalletPayoutStatus.values, json['payoutStatus']) ??
          EwalletPayoutStatus.notApplicable,
      payoutTransactionId: json['payoutTransactionId'] as String?,
      redemptionReference: json['redemptionReference'] as String?,
      pointsCost: json['pointsCost'] as int? ?? 0,
      cancelledAt: _date(json['cancelledAt']),
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
    'status': statusOverride?.name,
    'value': value,
    'merchant': merchant,
    'terms': terms,
    'targetPhone': targetPhone,
    'ewalletProvider': ewalletProvider,
    'payoutStatus': payoutStatus.name,
    'payoutTransactionId': payoutTransactionId,
    'redemptionReference': redemptionReference,
    'pointsCost': pointsCost,
    'cancelledAt': cancelledAt?.toIso8601String(),
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  static T? _enumValue<T extends Enum>(List<T> values, Object? value) =>
      values.where((item) => item.name == value).firstOrNull;
}

typedef Voucher = RewardVoucher;
