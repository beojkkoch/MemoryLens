import 'package:memorylens/features/auth/domain/entities/profile.dart';

enum ProfileStatus { loading, loaded, failure, signedOut }

/// Single state of the profile screen; status says which moment it is.
class ProfileState {
  final ProfileStatus status;
  final Profile? profile;
  final bool signingOut;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.loading,
    this.profile,
    this.signingOut = false,
    this.errorMessage,
  });

  /// errorMessage is not carried over: every copy clears it unless given.
  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    bool? signingOut,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      signingOut: signingOut ?? this.signingOut,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'ProfileState(status: ${status.name}, '
        'signingOut: $signingOut, error: $errorMessage)';
  }
}
