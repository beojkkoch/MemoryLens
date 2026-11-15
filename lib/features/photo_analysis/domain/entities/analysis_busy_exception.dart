/// The AI asked to wait: the free plan allows only so many requests a minute,
/// or the model is overloaded. Waiting [retryAfter] and trying again fixes it.
class AnalysisBusyException implements Exception {
  final Duration retryAfter;

  const AnalysisBusyException(this.retryAfter);

  @override
  String toString() => 'AnalysisBusyException(retryAfter: $retryAfter)';
}
