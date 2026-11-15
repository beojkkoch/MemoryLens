import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';

/// The corrections of a photo, as the detail sends them when the person
/// presses «Hecho» (HU-30).
///
/// While editing, the detail only hides the purchase fields of a category
/// that is not «Factura» and keeps what they hold. They are cleared here,
/// by [toSave], and only when saving (HU-29, CA3).
class PhotoEdit {
  /// For an amount typed in a photo that had none. The app is made for
  /// Colombia first.
  static const defaultCurrency = 'COP';

  final String? category;
  final String? purchaseType;
  final Money? total;

  const PhotoEdit({this.category, this.purchaseType, this.total});

  /// What gets saved: outside «Factura» the purchase data is dropped (CA3).
  PhotoEdit toSave() {
    if (PhotoDetail.hasPurchaseFields(category)) return this;
    return PhotoEdit(category: category);
  }

  @override
  bool operator ==(Object other) =>
      other is PhotoEdit &&
      other.category == category &&
      other.purchaseType == purchaseType &&
      other.total == total;

  @override
  int get hashCode => Object.hash(category, purchaseType, total);

  @override
  String toString() => 'PhotoEdit($category, $purchaseType, $total)';
}
