/// A photo found in the device gallery. It only carries what the import needs
/// to know about it, never the pixels.
class DeviceGalleryPhoto {
  /// Id of the photo on this device. It is only unique on this device.
  final String assetId;

  /// When the photo was taken, or null when the device has no date for it.
  final DateTime? takenAt;

  const DeviceGalleryPhoto({required this.assetId, this.takenAt});
}
