import 'package:ecotrash/features/auth/data/repositories/local_auth_repository.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:ecotrash/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecotrash/features/auth/domain/services/otp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // TODO: Replace the local repository with a Firebase Auth implementation.
  return LocalAuthRepository();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

final currentRoleProvider = Provider<UserRole?>(
  (ref) => ref.watch(authControllerProvider).asData?.value?.role,
);

final otpServiceProvider = Provider<OtpService>((ref) => MockOtpService());

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<AuthUser?> register({
    required String name,
    String? email,
    String? phone,
    required String password,
    UserRole role = UserRole.pengguna,
    MitraProfile? mitraProfile,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(
            name: name,
            email: email,
            phone: phone,
            password: password,
            role: role,
            mitraProfile: mitraProfile,
          ),
    );
    state = result;
    return result.when(
      data: (user) => user,
      error: (_, _) => null,
      loading: () => null,
    );
  }

  Future<AuthUser?> signIn({
    String? email,
    String? phone,
    required String password,
    UserRole role = UserRole.pengguna,
    bool remember = true,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signIn(
            email: email,
            phone: phone,
            password: password,
            role: role,
            remember: remember,
          ),
    );
    state = result;
    return result.when(
      data: (user) => user,
      error: (_, _) => null,
      loading: () => null,
    );
  }

  Future<AuthUser?> signInWithOtp({
    required String phone,
    UserRole role = UserRole.pengguna,
    bool remember = true,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithOtp(phone: phone, role: role, remember: remember),
    );
    state = result;
    return result.asData?.value;
  }

  Future<AuthUser?> updateDisplayName(String name) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).updateDisplayName(name),
    );
    state = result;
    return result.asData?.value;
  }

  Future<bool> signOut() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      return null;
    });
    state = result;
    return !result.hasError;
  }
}
