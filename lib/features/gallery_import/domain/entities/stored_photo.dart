/// Where an imported photo and its thumbnail live in the person's storage.
/// Both are paths inside the bucket, not URLs: a signed URL is asked for when
/// the photo is shown.
class StoredPhoto {
  final String imagePath;
  final String thumbnailPath;

  const StoredPhoto({required this.imagePath, required this.thumbnailPath});
}
