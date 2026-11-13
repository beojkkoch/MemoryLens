import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/data/mapper/error_report_row.dart';
import 'package:memorylens/features/error_handling/domain/entities/error_report.dart';

void main() {
  const report = ErrorReport(
    screen: '/login',
    action: 'LoginSubmitted',
    errorType: 'StateError',
    message: 'Bad state: boom',
    stackTrace: '#0 main',
  );

  test('maps the report to the columns of registro_error', () {
    expect(errorReportToRow(report, platform: 'android'), {
      'pantalla': '/login',
      'accion': 'LoginSubmitted',
      'tipo': 'StateError',
      'mensaje': 'Bad state: boom',
      'stack_trace': '#0 main',
      'plataforma': 'android',
    });
  });

  test('cuts long text so the insert never breaks the table limits', () {
    final long = ErrorReport(
      screen: 's' * 500,
      action: 'a' * 500,
      errorType: 't' * 500,
      message: 'm' * 5000,
      stackTrace: 'x' * 20000,
    );

    final row = errorReportToRow(long, platform: 'web');

    expect((row['pantalla'] as String).length, lessThanOrEqualTo(200));
    expect((row['accion'] as String).length, lessThanOrEqualTo(200));
    expect((row['tipo'] as String).length, lessThanOrEqualTo(200));
    expect((row['mensaje'] as String).length, lessThanOrEqualTo(2000));
    expect((row['stack_trace'] as String).length, lessThanOrEqualTo(8000));
  });

  test('keeps a missing stack trace as null', () {
    const withoutStack = ErrorReport(
      screen: '/',
      action: 'x',
      errorType: 'StateError',
      message: 'm',
    );

    expect(
      errorReportToRow(withoutStack, platform: 'ios')['stack_trace'],
      isNull,
    );
  });
}
