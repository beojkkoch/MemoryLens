/// Something the profile screen asks the ProfileBloc to do.
abstract class ProfileEvent {}

/// The screen opened (or the user tapped retry) and needs the profile.
class ProfileRequested extends ProfileEvent {
  @override
  String toString() {
    return 'ProfileRequested()';
  }
}

/// The user tapped the sign out button.
class ProfileSignOutRequested extends ProfileEvent {
  @override
  String toString() {
    return 'ProfileSignOutRequested()';
  }
}
