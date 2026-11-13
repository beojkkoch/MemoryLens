import 'package:memorylens/features/auth/domain/entities/interest.dart';

enum RegisterStatus { initial, loading, success, failure }

enum InterestsStatus { loading, loaded, failure }

/// Single state of the register screen; status says which moment it is.
class RegisterState {
  final RegisterStatus status;
  final InterestsStatus interestsStatus;
  final List<Interest> interests;
  final String? errorMessage;

  /// Why the interests could not load; only read while interestsStatus fails.
  final String? interestsError;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.interestsStatus = InterestsStatus.loading,
    this.interests = const [],
    this.errorMessage,
    this.interestsError,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    InterestsStatus? interestsStatus,
    List<Interest>? interests,
    String? errorMessage,
    String? interestsError,
  }) {
    return RegisterState(
      status: status ?? this.status,
      interestsStatus: interestsStatus ?? this.interestsStatus,
      interests: interests ?? this.interests,
      errorMessage: errorMessage ?? this.errorMessage,
      interestsError: interestsError ?? this.interestsError,
    );
  }

  @override
  String toString() {
    return 'RegisterState(status: ${status.name}, '
        'interests: ${interestsStatus.name}, error: $errorMessage)';
  }
}
