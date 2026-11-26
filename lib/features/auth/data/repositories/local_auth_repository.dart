import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:ecotrash/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecotrash/features/auth/domain/use_cases/auth_validation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    FlutterSecureStorage? secureStorage,
    this._demoAutoVerifyMitra = true,
    this.inMemory = false,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock,
             ),
           );

  static const _accountsBox = 'eco_auth_accounts';
  static const _sessionKey = 'eco_auth_session';
  static const _lockoutBox = 'eco_auth_lockouts';
  static const _mitraBox = 'eco_auth_mitra_profiles';
  static const _sessionFallbackBox = 'eco_auth_session_fallback';

  final FlutterSecureStorage _secureStorage;
  final bool _demoAutoVerifyMitra;
  final bool inMemory;
  Box<String>? _accounts;
  Box<String>? _lockouts;
  Box<String>? _profiles;
  Box<String>? _sessionFallback;
  AuthUser? _memorySession;
  bool _initialized = false;

  static final Map<String, String> _memoryAccounts = {};
  static final Map<String, String> _memoryLockouts = {};
  static final Map<String, String> _memoryProfiles = {};
  static String? _memorySessionJson;

  static void resetInMemory() {
    _memoryAccounts.clear();
    _memoryLockouts.clear();
    _memoryProfiles.clear();
    _memorySessionJson = null;
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    if (inMemory) {
      _initialized = true;
      return;
    }
    try {
      await Hive.initFlutter();
    } catch (_) {
      Hive.init('eco_auth_hive');
    }
    _accounts = await Hive.openBox<String>(_accountsBox);
    _lockouts = await Hive.openBox<String>(_lockoutBox);
    _profiles = await Hive.openBox<String>(_mitraBox);
    _sessionFallback = await Hive.openBox<String>(_sessionFallbackBox);
    _initialized = true;
  }

  Iterable<String> get _accountValues =>
      inMemory ? _memoryAccounts.values : _accounts?.values ?? const <String>[];

  String? _accountGet(String id) =>
      inMemory ? _memoryAccounts[id] : _accounts?.get(id);

  Future<void> _accountPut(String id, String value) async {
    if (inMemory) {
      _memoryAccounts[id] = value;
    } else {
      await _accounts?.put(id, value);
    }
  }

  String? _lockoutGet(String key) =>
      inMemory ? _memoryLockouts[key] : _lockouts?.get(key);

  Future<void> _lockoutPut(String key, String value) async {
    if (inMemory) {
      _memoryLockouts[key] = value;
    } else {
      await _lockouts?.put(key, value);
    }
  }

  Future<void> _lockoutDelete(String key) async {
    if (inMemory) {
      _memoryLockouts.remove(key);
    } else {
      await _lockouts?.delete(key);
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    await _initialize();
    if (_memorySession != null) return _memorySession;
    if (!inMemory) {
      final preferences = await SharedPreferences.getInstance();
      final legacyId = preferences.getString('auth_user_id');
      final legacyName = preferences.getString('auth_user_name');
      final legacyEmail = preferences.getString('auth_user_email');
      if (legacyId != null && legacyName != null && legacyEmail != null) {
        final legacyUser = AppUser(
          id: legacyId,
          role: UserRole.pengguna,
          name: legacyName,
          email: legacyEmail,
          passwordHash: '',
          salt: '',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        _memorySession = legacyUser;
        return legacyUser;
      }
    }
    String? sessionJson;
    if (inMemory) {
      sessionJson = _memorySessionJson;
    } else {
      try {
        sessionJson = await _secureStorage.read(key: _sessionKey);
      } catch (_) {
        sessionJson = null;
      }
      sessionJson ??= _sessionFallback?.get(_sessionKey);
    }
    if (sessionJson == null) return null;
    try {
      final session = jsonDecode(sessionJson) as Map<String, dynamic>;
      final expiresAtValue = session['expiresAt'] as String?;
      final expiresAt = expiresAtValue == null
          ? null
          : DateTime.tryParse(expiresAtValue);
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        await signOut();
        return null;
      }
      final user = _accountGet(session['userId'] as String);
      if (user == null) return null;
      _memorySession = AppUser.fromJson(
        jsonDecode(user) as Map<String, dynamic>,
      );
      return _memorySession;
    } catch (_) {
      await signOut();
      return null;
    }
  }

  @override
  Future<AuthUser> register({
    required String name,
    String? email,
    String? phone,
    required String password,
    UserRole role = UserRole.pengguna,
    MitraProfile? mitraProfile,
  }) async {
    await _initialize();
    final normalizedName = name.trim();
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPhone = phone == null ? null : normalizePhone(phone);
    if (normalizedName.length < 3) {
      throw const AuthException('Nama minimal 3 karakter.');
    }
    if (normalizedEmail != null && !isValidEmail(normalizedEmail)) {
      throw const AuthException('Format email tidak valid.');
    }
    if (normalizedPhone == null && normalizedEmail == null) {
      throw const AuthException('Email atau nomor telepon wajib diisi.');
    }
    if (!isValidPassword(password)) {
      throw const AuthException(
        'Kata sandi minimal 8 karakter dan mengandung huruf serta angka.',
      );
    }
    for (final value in _accountValues) {
      final existing = AppUser.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
      if (normalizedEmail != null &&
          existing.email?.toLowerCase() == normalizedEmail) {
        throw const AuthException('Email sudah terdaftar. Silakan masuk.');
      }
      if (normalizedPhone != null && existing.phone == normalizedPhone) {
        throw const AuthException(
          'Nomor telepon sudah terdaftar. Silakan masuk.',
        );
      }
    }

    final salt = _randomBytes(16);
    final user = AppUser(
      id: const Uuid().v4(),
      role: role,
      name: normalizedName,
      email: normalizedEmail,
      phone: normalizedPhone,
      passwordHash: _hashPassword(password, salt),
      salt: base64Url.encode(salt),
      emailVerified: normalizedEmail != null,
      phoneVerified: normalizedPhone != null,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await _accountPut(user.id, jsonEncode(user.toJson()));

    if (mitraProfile != null) {
      final profile = MitraProfile(
        userId: user.id,
        name: mitraProfile.name,
        address: mitraProfile.address,
        latitude: mitraProfile.latitude,
        longitude: mitraProfile.longitude,
        operatingHours: mitraProfile.operatingHours,
        acceptedWasteTypes: mitraProfile.acceptedWasteTypes,
        contactNumber: mitraProfile.contactNumber,
        licenseNumber: mitraProfile.licenseNumber,
        description: mitraProfile.description,
        photoUrl: mitraProfile.photoUrl,
        status: _demoAutoVerifyMitra
            ? VerificationStatus.disetujui
            : VerificationStatus.menunggu,
      );
      if (inMemory) {
        _memoryProfiles[user.id] = jsonEncode(profile.toJson());
      } else {
        await _profiles?.put(user.id, jsonEncode(profile.toJson()));
      }
    }
    await _saveSession(user, remember: true);
    return user;
  }

  @override
  Future<AppUser> signIn({
    String? email,
    String? phone,
    required String password,
    UserRole role = UserRole.pengguna,
    bool remember = true,
  }) async {
    await _initialize();
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPhone = phone == null ? null : normalizePhone(phone);
    AppUser? account;
    for (final value in _accountValues) {
      final candidate = AppUser.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
      if (candidate.role != role) continue;
      if (normalizedEmail != null &&
          candidate.email?.toLowerCase() == normalizedEmail) {
        account = candidate;
        break;
      }
      if (normalizedPhone != null && candidate.phone == normalizedPhone) {
        account = candidate;
        break;
      }
    }
    if (account == null) {
      throw const AuthException('Akun belum terdaftar. Silakan daftar.');
    }
    final lockUntil = _lockoutGet(account.id);
    if (lockUntil != null) {
      final until = DateTime.tryParse(lockUntil);
      if (until != null && until.isAfter(DateTime.now())) {
        throw const AuthException(
          'Terlalu banyak percobaan. Coba lagi dalam 5 menit.',
        );
      }
      await _lockoutDelete(account.id);
    }
    final salt = base64Url.decode(account.salt);
    if (!_constantTimeEquals(
      account.passwordHash,
      _hashPassword(password, salt),
    )) {
      await _recordFailure(account.id);
      throw const AuthException('Email/nomor atau kata sandi salah.');
    }
    await _lockoutDelete(account.id);
    final updated = account.copyWith(lastLoginAt: DateTime.now());
    await _accountPut(account.id, jsonEncode(updated.toJson()));
    await _saveSession(updated, remember: remember);
    return updated;
  }

  @override
  Future<AppUser> signInWithOtp({
    required String phone,
    required UserRole role,
    bool remember = true,
  }) async {
    await _initialize();
    final normalizedPhone = normalizePhone(phone);
    for (final value in _accountValues) {
      final candidate = AppUser.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
      if (candidate.role == role && candidate.phone == normalizedPhone) {
        final updated = candidate.copyWith(lastLoginAt: DateTime.now());
        await _accountPut(candidate.id, jsonEncode(updated.toJson()));
        await _saveSession(updated, remember: remember);
        return updated;
      }
    }
    throw const AuthException('Akun belum terdaftar. Silakan daftar.');
  }

  Future<void> _recordFailure(String userId) async {
    final key = 'failed_$userId';
    final count = int.tryParse(_lockoutGet(key) ?? '0') ?? 0;
    final next = count + 1;
    await _lockoutPut(key, next.toString());
    if (next >= 5) {
      await _lockoutPut(
        userId,
        DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      );
      await _lockoutDelete(key);
    }
  }

  @override
  Future<AuthUser> updateDisplayName(String name) async {
    await _initialize();
    final user = await getCurrentUser();
    if (user == null) {
      throw const AuthException('Sesi tidak ditemukan. Silakan masuk kembali.');
    }
    final normalized = name.trim();
    if (normalized.length < 3) {
      throw const AuthException('Nama minimal 3 karakter.');
    }
    final updated = user.copyWith(name: normalized);
    await _accountPut(updated.id, jsonEncode(updated.toJson()));
    _memorySession = updated;
    return updated;
  }

  @override
  Future<void> signOut() async {
    _memorySession = null;
    if (inMemory) {
      _memorySessionJson = null;
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('auth_user_id');
    await preferences.remove('auth_user_name');
    await preferences.remove('auth_user_email');
    try {
      await _secureStorage.delete(key: _sessionKey);
    } catch (_) {}
    await _sessionFallback?.delete(_sessionKey);
  }

  Future<void> _saveSession(AppUser user, {required bool remember}) async {
    if (!remember) {
      _memorySession = user;
      return;
    }
    final expiresAt = remember
        ? DateTime.now().add(const Duration(days: 30)).toIso8601String()
        : null;
    final sessionJson = jsonEncode({
      'userId': user.id,
      'role': user.role.name,
      'expiresAt': expiresAt,
      'remember': remember,
    });
    if (inMemory) {
      _memorySessionJson = sessionJson;
      _memorySession = user;
      return;
    }
    try {
      await _secureStorage.write(key: _sessionKey, value: sessionJson);
      await _sessionFallback?.delete(_sessionKey);
    } catch (_) {
      await _sessionFallback?.put(_sessionKey, sessionJson);
    }
    _memorySession = user;
  }

  String _hashPassword(String password, List<int> salt) {
    var bytes = utf8.encode(password);
    var digest = <int>[];
    for (var i = 0; i < 10000; i++) {
      final hmac = Hmac(sha256, [...salt, ...bytes]);
      digest = hmac
          .convert(digest.isEmpty ? utf8.encode(password) : digest)
          .bytes;
    }
    return base64Url.encode(digest);
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var i = 0; i < left.length; i++) {
      difference |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
    }
    return difference == 0;
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
