import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> getCurrentUser();

  Future<AuthUser> register({
    required String name,
    String? email,
    String? phone,
    required String password,
    UserRole role = UserRole.pengguna,
    MitraProfile? mitraProfile,
  });

  Future<AuthUser> signIn({
    String? email,
    String? phone,
    required String password,
    UserRole role = UserRole.pengguna,
    bool remember = true,
  });

  Future<AuthUser> signInWithOtp({
    required String phone,
    required UserRole role,
    bool remember = true,
  });

  Future<AuthUser> updateDisplayName(String name);

  Future<void> signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
