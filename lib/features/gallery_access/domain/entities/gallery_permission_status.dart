/// Where the device permission to read photos stands.
enum GalleryPermissionStatus {
  /// The device lets the app read photos (iOS limited access counts too).
  granted,

  /// Not allowed, but the person can still be asked again.
  denied,

  /// Not allowed and the device will not ask again: only the system settings
  /// can change it.
  blocked,
}
