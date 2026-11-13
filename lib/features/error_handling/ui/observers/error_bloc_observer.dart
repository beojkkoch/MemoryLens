import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/error_handling/domain/usecases/report_error_usecase.dart';
import 'package:memorylens/features/error_handling/ui/observers/screen_tracker.dart';

/// Sends the errors that blocs report to the team log, with the screen and
/// the event that was running.
class ErrorBlocObserver extends BlocObserver {
  final ScreenTracker _tracker;
  final ReportErrorUseCase _report;

  /// Last event of each bloc. An Expando does not keep closed blocs alive.
  final Expando<String> _lastEvent = Expando<String>();

  ErrorBlocObserver({required this._tracker, required this._report});

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    // Only the type: the event fields can hold emails or passwords.
    _lastEvent[bloc] = event.runtimeType.toString();
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    unawaited(
      _report(
        screen: _tracker.screen,
        action: _lastEvent[bloc] ?? bloc.runtimeType.toString(),
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
