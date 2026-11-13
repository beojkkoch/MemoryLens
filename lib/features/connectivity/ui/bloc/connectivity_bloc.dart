import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/connectivity/domain/usecases/watch_connectivity_usecase.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_event.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_state.dart';
import 'package:memorylens/injection_container.dart';

/// Turns the connection stream into the state that shows or hides the
/// «Sin conexión» banner.
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final WatchConnectivityUseCase _watch = sl();

  ConnectivityBloc() : super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onStarted);
  }

  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) {
    return emit.forEach<bool>(
      _watch(),
      onData: (online) => ConnectivityState(online: online),
      onError: (error, stack) {
        // If the check fails, better no banner than a false one.
        addError(error, stack);
        return state;
      },
    );
  }
}
