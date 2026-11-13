import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/login/ui/bloc/login_event.dart';
import 'package:memorylens/features/login/ui/bloc/login_state.dart';
import 'package:memorylens/injection_container.dart';

/// Turns the sign in form into a call to SignInUsecase.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignInUsecase _signIn = sl();

  LoginBloc() : super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      await _signIn(email: event.email, password: event.password);
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e, stack) {
      // addError lets the error observer log it; the screen only gets the
      // friendly message.
      addError(e, stack);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: AppException.messageFor(e),
        ),
      );
    }
  }
}
