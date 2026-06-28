/// Functional result returned by platform services instead of throwing.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R fold<R>(R Function(T value) onSuccess, R Function(PlatformException error) onFailure) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Failure<T>(:final error) => onFailure(error),
    };
  }
}

/// Successful result value.
class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

/// Failed result value.
class Failure<T> extends Result<T> {
  const Failure(this.error);
  final PlatformException error;
}

/// Base platform exception model carried by [Result] failures.
class PlatformException implements Exception {
  const PlatformException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message ($cause)';
}

/// Returned when a device is not online or cannot be reached.
class DeviceDisconnectedException extends PlatformException {
  const DeviceDisconnectedException(super.message, {super.cause});
}

/// Returned when an ADB command exits unsuccessfully.
class ADBCommandException extends PlatformException {
  const ADBCommandException(super.message, {super.cause, this.exitCode});
  final int? exitCode;
}
