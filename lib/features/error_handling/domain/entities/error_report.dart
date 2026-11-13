/// One technical error, with where it happened, for the team to read.
class ErrorReport {
  /// Route of the screen the person was on.
  final String screen;

  /// What was running: the bloc event or the framework task.
  final String action;

  /// Class of the raw error, like ClientException.
  final String errorType;
  final String message;
  final String? stackTrace;

  const ErrorReport({
    required this.screen,
    required this.action,
    required this.errorType,
    required this.message,
    this.stackTrace,
  });
}
