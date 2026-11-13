import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/error_handling/domain/repository/error_log_repository.dart';
import 'package:memorylens/features/error_handling/domain/usecases/report_error_usecase.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_error_log_repository.dart';

void main() {
  late FakeErrorLogRepository log;
  late ReportErrorUseCase report;

  setUp(() async {
    await sl.reset();
    log = FakeErrorLogRepository();
    sl.registerSingleton<ErrorLogRepository>(log);
    report = ReportErrorUseCase();
  });

  test('a technical error is logged with its screen and action', () async {
    await report(
      screen: '/login',
      action: 'LoginSubmitted',
      error: StateError('boom'),
      stackTrace: StackTrace.fromString('#0 main'),
    );

    final saved = log.reports.single;
    expect(saved.screen, '/login');
    expect(saved.action, 'LoginSubmitted');
    expect(saved.errorType, 'StateError');
    expect(saved.message, contains('boom'));
    expect(saved.stackTrace, contains('#0 main'));
  });

  test('a mapped error is logged with the raw error behind it', () async {
    final mapped = ExceptionMapper.map(http.ClientException('Failed host'));

    await report(screen: '/profile', action: 'ProfileRequested', error: mapped);

    final saved = log.reports.single;
    expect(saved.errorType, 'ClientException');
    expect(saved.message, contains('Failed host'));
  });

  test('an error the person can fix is not logged', () async {
    await report(
      screen: '/login',
      action: 'LoginSubmitted',
      error: const AppException('Correo o contraseña incorrectos'),
    );

    expect(log.reports, isEmpty);
  });

  test('a log that cannot even be created never throws', () async {
    // Supabase failed to start, so the repository could not be built.
    await sl.reset();

    await expectLater(
      ReportErrorUseCase()(screen: '/', action: 'main', error: StateError('x')),
      completes,
    );
  });

  test('a log that cannot be written never throws', () async {
    log.error = Exception('no connection');

    await expectLater(
      report(
        screen: '/login',
        action: 'LoginSubmitted',
        error: StateError('x'),
      ),
      completes,
    );
  });
}
