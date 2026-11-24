import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:ecotrash/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthRepository implements AuthRepository {
  final Map<String, _LocalAccount> _accounts = {};

  @override
  Future<AuthUser?> getCurrentUser() async {
    final preferences = await SharedPreferences.getInstance();
    final id = preferences.getString(AppStorageKeys.authUserId);
    final name = preferences.getString(AppStorageKeys.authUserName);
    final email = preferences.getString(AppStorageKeys.authUserEmail);

    if (id == null || name == null || email == null) {
      await _clearSession(preferences);
      return null;
    }

    return AuthUser(id: id, name: name, email: email);
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      throw const AuthException('Nama wajib diisi.');
    }
    if (!_isValidEmail(normalizedEmail)) {
      throw const AuthException('Format email tidak valid.');
    }
    if (password.length < 8) {
      throw const AuthException('Kata sandi minimal 8 karakter.');
    }
    if (_accounts.containsKey(normalizedEmail)) {
      throw const AuthException('Email sudah terdaftar.');
    }

    final user = AuthUser(
      id: normalizedEmail,
      name: normalizedName,
      email: normalizedEmail,
    );
    _accounts[normalizedEmail] = _LocalAccount(user, password);
    await _saveSession(user);
    return user;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null || account.password != password) {
      throw const AuthException('Email atau kata sandi tidak sesuai.');
    }

    await _saveSession(account.user);
    return account.user;
  }

  @override
  Future<AuthUser> updateDisplayName(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const AuthException('Nama wajib diisi.');
    }
    final user = await getCurrentUser();
    if (user == null) {
      throw const AuthException('Sesi tidak ditemukan. Silakan masuk kembali.');
    }
    final updatedUser = AuthUser(
      id: user.id,
      name: normalizedName,
      email: user.email,
    );
    await _saveSession(updatedUser);
    final account = _accounts[user.email];
    if (account != null) {
      account.user = updatedUser;
    }
    return updatedUser;
  }

  @override
  Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await _clearSession(preferences);
  }

  Future<void> _saveSession(AuthUser user) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await Future.wait([
      preferences.setString(AppStorageKeys.authUserId, user.id),
      preferences.setString(AppStorageKeys.authUserName, user.name),
      preferences.setString(AppStorageKeys.authUserEmail, user.email),
    ]);

    if (saved.contains(false)) {
      await _clearSession(preferences);
      throw const AuthException('Sesi tidak dapat disimpan. Coba lagi.');
    }
  }

  Future<void> _clearSession(SharedPreferences preferences) async {
    await Future.wait([
      preferences.remove(AppStorageKeys.authUserId),
      preferences.remove(AppStorageKeys.authUserName),
      preferences.remove(AppStorageKeys.authUserEmail),
    ]);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}

class _LocalAccount {
  _LocalAccount(this.user, this.password);

  AuthUser user;
  final String password;
}
