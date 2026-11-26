sealed class AuthFailure {
  const AuthFailure();
}

class AccountAlreadyExistsFailure extends AuthFailure {}

class InvalidCredentialsFailure extends AuthFailure {}

class AccountNotFoundFailure extends AuthFailure {}

class OtpInvalidFailure extends AuthFailure {}

class OtpExpiredFailure extends AuthFailure {}

class TooManyAttemptsFailure extends AuthFailure {
  const TooManyAttemptsFailure(this.retryAfter);

  final Duration retryAfter;
}

class NetworkFailure extends AuthFailure {}

class UnknownFailure extends AuthFailure {
  const UnknownFailure(this.message);

  final String message;
}

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AuthFailure failure;
}
