import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/error_handling/domain/repository/error_log_repository.dart';
import 'package:memorylens/features/error_handling/domain/usecases/report_error_usecase.dart';
import 'package:memorylens/features/error_handling/ui/observers/error_bloc_observer.dart';
import 'package:memorylens/features/error_handling/ui/observers/screen_tracker.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_error_log_repository.dart';

class _Save {}

/// Bloc that reports the error it is told to, like the app blocs do.
class _FailingBloc extends Bloc<_Save, int> {
  final Object error;

  _FailingBloc(this.error) : super(0) {
    on<_Save>((event, emit) => addError(error, StackTrace.current));
  }
}

/// Does nothing; puts back a harmless observer after each test.
class _SilentObserver extends BlocObserver {}

Route<void> _route(String? name) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox(),
  );
}

void main() {
  late FakeErrorLogRepository log;
  late ScreenTracker tracker;

  setUp(() async {
    await sl.reset();
    log = FakeErrorLogRepository();
    sl.registerSingleton<ErrorLogRepository>(log);
    tracker = ScreenTracker();
  });

  group('ScreenTracker', () {
    test('starts without a known screen', () {
      expect(tracker.screen, ScreenTracker.unknownScreen);
    });

    test('follows the route that was pushed', () {
      tracker.didPush(_route('/login'), null);

      expect(tracker.screen, '/login');
    });

    test('goes back to the previous route on pop', () {
      final login = _route('/login');
      final welcome = _route('/');
      tracker.didPush(welcome, null);
      tracker.didPush(login, welcome);

      tracker.didPop(login, welcome);

      expect(tracker.screen, '/');
    });

    test('follows a replaced route', () {
      tracker.didPush(_route('/login'), null);

      tracker.didReplace(
        newRoute: _route('/register'),
        oldRoute: _route('/login'),
      );

      expect(tracker.screen, '/register');
    });

    test('ignores routes without a name, like dialogs', () {
      tracker.didPush(_route('/profile'), null);

      tracker.didPush(_route(null), null);

      expect(tracker.screen, '/profile');
    });

    test('keeps the new screen when the old routes are removed', () {
      final welcome = _route('/');
      final profile = _route('/profile');
      tracker.didPush(profile, welcome);

      tracker.didRemove(welcome, null);

      expect(tracker.screen, '/profile');
    });
  });

  group('ErrorBlocObserver', () {
    late ErrorBlocObserver observer;

    setUp(() {
      observer = ErrorBlocObserver(
        tracker: tracker,
        report: ReportErrorUseCase(),
      );
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = _SilentObserver());
    });

    test('logs the screen and the event that was running', () async {
      tracker.didPush(_route('/login'), null);
      final bloc = _FailingBloc(StateError('boom'));
      addTearDown(bloc.close);

      bloc.add(_Save());
      await pumpEventQueue();

      final saved = log.reports.single;
      expect(saved.screen, '/login');
      expect(saved.action, '_Save');
      expect(saved.errorType, 'StateError');
    });

    test('does not log an error the person can fix', () async {
      final bloc = _FailingBloc(
        const AppException('Correo o contraseña incorrectos'),
      );
      addTearDown(bloc.close);

      bloc.add(_Save());
      await pumpEventQueue();

      expect(log.reports, isEmpty);
    });

    test('a failing log does not break the bloc', () async {
      log.error = Exception('offline');
      final bloc = _FailingBloc(StateError('boom'));
      addTearDown(bloc.close);

      bloc.add(_Save());
      await pumpEventQueue();

      expect(bloc.state, 0);
    });
  });
}
