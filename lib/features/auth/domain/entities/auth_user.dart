enum UserRole { pengguna, mitra }

enum VerificationStatus { menunggu, disetujui, ditolak }

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    required this.lastLoginAt,
    this.email,
    this.phone,
    this.photoUrl,
    this.emailVerified = false,
    this.phoneVerified = false,
  });

  final String id;
  final UserRole role;
  final String name;
  final String? email;
  final String? phone;
  final String passwordHash;
  final String salt;
  final String? photoUrl;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  String get emailValue => email ?? '';

  AppUser copyWith({
    String? id,
    UserRole? role,
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    String? salt,
    String? photoUrl,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) => AppUser(
    id: id ?? this.id,
    role: role ?? this.role,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
    photoUrl: photoUrl ?? this.photoUrl,
    emailVerified: emailVerified ?? this.emailVerified,
    phoneVerified: phoneVerified ?? this.phoneVerified,
    createdAt: createdAt ?? this.createdAt,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'name': name,
    'email': email,
    'phone': phone,
    'passwordHash': passwordHash,
    'salt': salt,
    'photoUrl': photoUrl,
    'emailVerified': emailVerified,
    'phoneVerified': phoneVerified,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    role: UserRole.values.firstWhere(
      (role) => role.name == json['role'],
      orElse: () => UserRole.pengguna,
    ),
    name: json['name'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    passwordHash: json['passwordHash'] as String,
    salt: json['salt'] as String,
    photoUrl: json['photoUrl'] as String?,
    emailVerified: json['emailVerified'] == true,
    phoneVerified: json['phoneVerified'] == true,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

typedef AuthUser = AppUser;

class MitraProfile {
  const MitraProfile({
    required this.userId,
    required this.name,
    required this.address,
    required this.operatingHours,
    required this.acceptedWasteTypes,
    required this.contactNumber,
    required this.status,
    this.latitude,
    this.longitude,
    this.licenseNumber,
    this.description,
    this.photoUrl,
  });

  final String userId;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String operatingHours;
  final List<String> acceptedWasteTypes;
  final String contactNumber;
  final String? licenseNumber;
  final String? description;
  final String? photoUrl;
  final VerificationStatus status;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'operatingHours': operatingHours,
    'acceptedWasteTypes': acceptedWasteTypes,
    'contactNumber': contactNumber,
    'licenseNumber': licenseNumber,
    'description': description,
    'photoUrl': photoUrl,
    'status': status.name,
  };
}
