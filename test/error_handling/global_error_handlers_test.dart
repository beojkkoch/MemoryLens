import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/domain/repository/error_log_repository.dart';
import 'package:memorylens/features/error_handling/domain/usecases/report_error_usecase.dart';
import 'package:memorylens/features/error_handling/ui/global_error_handlers.dart';
import 'package:memorylens/features/error_handling/ui/observers/screen_tracker.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_error_log_repository.dart';

void main() {
  late FakeErrorLogRepository log;
  late ScreenTracker tracker;

  setUp(() async {
    await sl.reset();
    log = FakeErrorLogRepository();
    sl.registerSingleton<ErrorLogRepository>(log);
    tracker = ScreenTracker();
    tracker.didPush(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/profile'),
        builder: (_) => const SizedBox(),
      ),
      null,
    );

    // The handlers are global: put every one back after the test.
    final onError = FlutterError.onError;
    final onPlatformError = PlatformDispatcher.instance.onError;
    final errorWidgetBuilder = ErrorWidget.builder;
    addTearDown(() {
      FlutterError.onError = onError;
      PlatformDispatcher.instance.onError = onPlatformError;
      ErrorWidget.builder = errorWidgetBuilder;
    });
    installGlobalErrorHandlers(tracker: tracker, report: ReportErrorUseCase());
  });

  test(
    'a framework error is logged with the screen and what was doing',
    () async {
      // presentError would dump the whole error into the test output.
      final printer = debugPrint;
      debugPrint = (message, {wrapWidth}) {};
      addTearDown(() => debugPrint = printer);

      FlutterError.onError!(
        FlutterErrorDetails(
          exception: StateError('layout failed'),
          stack: StackTrace.current,
          context: ErrorDescription('while building the profile'),
        ),
      );
      await pumpEventQueue();

      final saved = log.reports.single;
      expect(saved.screen, '/profile');
      expect(saved.action, contains('while building the profile'));
      expect(saved.errorType, 'StateError');
    },
  );

  test('an error nobody caught is logged and does not crash the app', () async {
    final handled = PlatformDispatcher.instance.onError!(
      StateError('late failure'),
      StackTrace.current,
    );
    await pumpEventQueue();

    expect(handled, isTrue);
    final saved = log.reports.single;
    expect(saved.screen, '/profile');
    expect(saved.message, contains('late failure'));
  });

  testWidgets(
    'a widget that breaks shows a friendly message, not a red screen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorWidget.builder(
              FlutterErrorDetails(
                exception: Exception('RenderFlex overflowed'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Algo salió mal en esta sección'), findsOneWidget);
      expect(find.textContaining('RenderFlex'), findsNothing);
    },
  );
}
