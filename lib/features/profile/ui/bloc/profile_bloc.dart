import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memorylens/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_event.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_state.dart';
import 'package:memorylens/injection_container.dart';

/// Loads the profile and turns the sign out button into a SignOutUsecase call.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase _getProfile = sl();
  final SignOutUsecase _signOut = sl();

  ProfileBloc() : super(const ProfileState()) {
    on<ProfileRequested>(_onRequested);
    on<ProfileSignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _getProfile();
      emit(state.copyWith(status: ProfileStatus.loaded, profile: profile));
    } catch (e, stack) {
      addError(e, stack);
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: AppException.messageFor(e),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    ProfileSignOutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(signingOut: true));
    try {
      await _signOut();
      emit(state.copyWith(status: ProfileStatus.signedOut));
    } catch (e, stack) {
      addError(e, stack);
      // signingOut goes back to false so the button works again.
      emit(
        state.copyWith(
          signingOut: false,
          errorMessage: AppException.messageFor(e),
        ),
      );
    }
  }
}
