import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/connectivity/data/source/connectivity_data_source.dart';
import 'package:memorylens/features/connectivity/domain/repository/connectivity_repository.dart';
import 'package:memorylens/features/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_bloc.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_event.dart';
import 'package:memorylens/features/connectivity/ui/widgets/connectivity_shell.dart';
import 'package:memorylens/injection_container.dart';

/// Lets the test decide when the connection drops and comes back.
class FakeConnectivityRepository implements ConnectivityRepository {
  final controller = StreamController<bool>();

  @override
  Stream<bool> watch() => controller.stream;
}

void main() {
  late FakeConnectivityRepository connectivity;

  setUp(() async {
    await sl.reset();
    connectivity = FakeConnectivityRepository();
    // close() never completes for a stream nobody listened to: do not await.
    addTearDown(() => unawaited(connectivity.controller.close()));
    sl.registerSingleton<ConnectivityRepository>(connectivity);
    sl.registerLazySingleton(() => WatchConnectivityUseCase());
    sl.registerFactory(() => ConnectivityBloc());
  });

  group('ConnectivityDataSource.isOnline', () {
    test('no network at all is offline', () {
      expect(
        ConnectivityDataSource.isOnline([ConnectivityResult.none]),
        isFalse,
      );
    });

    test('wifi, mobile data or a cable is online', () {
      for (final result in [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
      ]) {
        expect(ConnectivityDataSource.isOnline([result]), isTrue);
      }
    });

    test('any working network is enough when there are several', () {
      expect(
        ConnectivityDataSource.isOnline([
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        isTrue,
      );
    });
  });

  group('ConnectivityBloc', () {
    test('starts online so the banner does not flash at launch', () {
      expect(ConnectivityBloc().state.online, isTrue);
    });

    test('follows the connection as it drops and comes back', () async {
      final bloc = ConnectivityBloc()..add(ConnectivityStarted());
      addTearDown(bloc.close);

      connectivity.controller.add(false);
      await pumpEventQueue();
      expect(bloc.state.online, isFalse);

      connectivity.controller.add(true);
      await pumpEventQueue();
      expect(bloc.state.online, isTrue);
    });

    test('a failing connectivity check does not show the banner', () async {
      final bloc = ConnectivityBloc()..add(ConnectivityStarted());
      addTearDown(bloc.close);

      connectivity.controller.addError(StateError('plugin failed'));
      await pumpEventQueue();

      expect(bloc.state.online, isTrue);
    });
  });

  group('ConnectivityShell', () {
    Future<void> pumpShell(WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => sl<ConnectivityBloc>()..add(ConnectivityStarted()),
          child: MaterialApp(
            builder: (context, child) => ConnectivityShell(child: child!),
            home: const Scaffold(body: Center(child: Text('Contenido'))),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows no banner while there is connection', (tester) async {
      await pumpShell(tester);
      connectivity.controller.add(true);
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión'), findsNothing);
      expect(find.text('Contenido'), findsOneWidget);
    });

    testWidgets('shows the banner when the connection drops and hides it '
        'when it is back', (tester) async {
      await pumpShell(tester);

      connectivity.controller.add(false);
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('Contenido'), findsOneWidget);

      connectivity.controller.add(true);
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión'), findsNothing);
      expect(find.text('Contenido'), findsOneWidget);
    });
  });
}
