import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:memorylens/components/error_fallback.dart';
import 'package:memorylens/features/error_handling/domain/usecases/report_error_usecase.dart';
import 'package:memorylens/features/error_handling/ui/observers/screen_tracker.dart';

/// Makes sure no error closes the app: every one is logged for the team and
/// a broken widget is swapped for a friendly message.
void installGlobalErrorHandlers({
  required ScreenTracker tracker,
  required ReportErrorUseCase report,
}) {
  // Errors thrown by the framework: build, layout, paint, gestures.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      report(
        screen: tracker.screen,
        action:
            details.context?.toDescription() ?? details.library ?? 'flutter',
        error: details.exception,
        stackTrace: details.stack,
      ),
    );
  };

  // Errors nobody caught. Returning true marks them as handled, so the app
  // keeps running.
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      report(
        screen: tracker.screen,
        action: 'error no capturado',
        error: error,
        stackTrace: stack,
      ),
    );
    return true;
  };

  ErrorWidget.builder = (details) => const ErrorFallback();
}
