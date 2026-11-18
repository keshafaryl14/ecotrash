import 'package:ecotrash/features/auth/domain/repositories/auth_repository.dart';

String authErrorMessage(Object error) {
  if (error is AuthException) {
    return error.message;
  }
  return 'Terjadi kesalahan. Silakan coba lagi.';
}
