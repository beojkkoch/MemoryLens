import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/auth/domain/usecases/get_interests_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/register/ui/bloc/register_event.dart';
import 'package:memorylens/features/register/ui/bloc/register_state.dart';
import 'package:memorylens/injection_container.dart';

/// Loads the interests and turns the sign up form into a call to SignUpUseCase.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final GetInterestsUseCase _getInterests = sl();
  final SignUpUseCase _signUp = sl();

  RegisterBloc() : super(const RegisterState()) {
    on<RegisterInterestsRequested>(_onInterestsRequested);
    on<RegisterSubmitted>(_onSubmitted);
  }

  Future<void> _onInterestsRequested(
    RegisterInterestsRequested event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(interestsStatus: InterestsStatus.loading));
    try {
      final interests = await _getInterests();
      emit(
        state.copyWith(
          interestsStatus: InterestsStatus.loaded,
          interests: interests,
        ),
      );
    } catch (e, stack) {
      addError(e, stack);
      emit(
        state.copyWith(
          interestsStatus: InterestsStatus.failure,
          interestsError: AppException.messageFor(e),
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(status: RegisterStatus.loading));
    try {
      await _signUp(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        city: event.city,
        profession: event.profession,
        interests: event.interests,
        newInterestNames: event.newInterestNames,
      );
      emit(state.copyWith(status: RegisterStatus.success));
    } catch (e, stack) {
      addError(e, stack);
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: AppException.messageFor(e),
        ),
      );
    }
  }
}
