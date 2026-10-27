import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';

enum RegisterStatus { initial, loading, success, failure }

enum InterestsStatus { loading, loaded, failure }

/// Single state of the register screen; status says which moment it is.
class RegisterState {
  final RegisterStatus status;
  final InterestsStatus interestsStatus;
  final List<Interest> interests;
  final Profile? profile;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.interestsStatus = InterestsStatus.loading,
    this.interests = const [],
    this.profile,
    this.errorMessage,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    InterestsStatus? interestsStatus,
    List<Interest>? interests,
    Profile? profile,
    String? errorMessage,
  }) {
    return RegisterState(
      status: status ?? this.status,
      interestsStatus: interestsStatus ?? this.interestsStatus,
      interests: interests ?? this.interests,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'RegisterState(status: ${status.name}, '
        'interests: ${interestsStatus.name}, error: $errorMessage)';
  }
}
