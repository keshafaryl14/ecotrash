import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> getCurrentUser();

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> updateDisplayName(String name);

  Future<void> signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
