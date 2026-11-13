/// What went wrong, in terms the app can react to.
enum AppErrorKind {
  /// The request never reached the server (no internet, DNS, refused).
  network,

  /// The server took too long to answer.
  timeout,

  /// The server answered with a failure.
  server,

  /// The data asked for does not exist.
  notFound,

  /// A normal outcome the person can fix, like a wrong password.
  expected,

  /// Anything else, usually a bug.
  unknown,
}

/// Error that already carries a message written for the person using the app.
///
/// Data sources translate every raw failure into one of these, so the blocs
/// and screens never see technical text.
class AppException implements Exception {
  /// Shown when an error did not come as an [AppException].
  static const genericMessage = 'Algo salió mal. Inténtalo de nuevo.';

  /// Spanish text without technical terms, safe to show on screen.
  final String message;
  final AppErrorKind kind;

  /// The raw error behind this one, kept only for the team log.
  final Object? cause;

  const AppException(
    this.message, {
    this.kind = AppErrorKind.expected,
    this.cause,
  });

  /// True when the team should hear about it. A wrong password is not.
  bool get technical => kind != AppErrorKind.expected;

  /// Text for the screen: the own message, or the generic one for anything
  /// that was not translated.
  static String messageFor(Object error) {
    if (error is AppException) return error.message;
    return genericMessage;
  }

  @override
  String toString() {
    final origin = cause == null ? '' : ' <- $cause';
    return 'AppException(${kind.name}): $message$origin';
  }
}
