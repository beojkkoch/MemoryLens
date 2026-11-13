import 'package:memorylens/features/error_handling/domain/entities/error_report.dart';

// These limits match the check constraints of registro_error.
const _maxShortLength = 200;
const _maxMessageLength = 2000;
const _maxStackLength = 8000;

/// Columns of the registro_error table for one report.
Map<String, dynamic> errorReportToRow(
  ErrorReport report, {
  required String platform,
}) {
  return {
    'pantalla': _cut(report.screen, _maxShortLength),
    'accion': _cut(report.action, _maxShortLength),
    'tipo': _cut(report.errorType, _maxShortLength),
    'mensaje': _cut(report.message, _maxMessageLength),
    'stack_trace': report.stackTrace == null
        ? null
        : _cut(report.stackTrace!, _maxStackLength),
    'plataforma': platform,
  };
}

String _cut(String text, int max) {
  return text.length <= max ? text : text.substring(0, max);
}
