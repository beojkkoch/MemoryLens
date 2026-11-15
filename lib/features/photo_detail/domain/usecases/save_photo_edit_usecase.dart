import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';
import 'package:memorylens/features/photo_detail/domain/repository/photo_detail_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Saves the corrections of the person to a photo (HU-30). The screen checks
/// the same rules first, so these only catch a screen that let one through.
class SavePhotoEditUseCase {
  static const missingCategoryMessage = 'Elige una categoría.';
  static const invalidAmountMessage = 'Escribe un monto mayor que 0.';

  final PhotoDetailRepository _photos = sl();

  Future<void> call(String photoId, PhotoEdit edit) {
    final toSave = edit.toSave();
    final category = toSave.category?.trim();
    if (category == null || category.isEmpty) {
      throw const AppException(missingCategoryMessage);
    }
    final amount = toSave.total?.amount;
    if (amount != null && amount <= 0) {
      throw const AppException(invalidAmountMessage);
    }
    return _photos.save(photoId, toSave);
  }
}
