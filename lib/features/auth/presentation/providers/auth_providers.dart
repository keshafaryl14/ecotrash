import 'package:ecotrash/features/auth/data/repositories/local_auth_repository.dart';
import 'package:ecotrash/features/auth/domain/entities/auth_user.dart';
import 'package:ecotrash/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // TODO: Replace the local repository with a Firebase Auth implementation.
  return LocalAuthRepository();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<AuthUser?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password),
    );
    state = result;
    return result.when(
      data: (user) => user,
      error: (_, _) => null,
      loading: () => null,
    );
  }

  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
    state = result;
    return result.when(
      data: (user) => user,
      error: (_, _) => null,
      loading: () => null,
    );
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
