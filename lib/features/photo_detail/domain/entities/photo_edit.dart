import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';

/// The data of a photo while the person corrects it in the detail, before
/// pressing «Hecho» (HU-30). It keeps the rule of which fields apply to each
/// category (HU-29).
///
/// Changing the category only hides or shows the purchase fields: their
/// values are kept, so going back to «Factura» before saving loses nothing.
/// They are cleared only by [toSave] (CA3).
class PhotoEdit {
  /// For an amount typed in a photo that had none. The app is made for
  /// Colombia first.
  static const defaultCurrency = 'COP';

  final String? category;
  final String? purchaseType;
  final Money? total;

  const PhotoEdit({this.category, this.purchaseType, this.total});

  factory PhotoEdit.from(PhotoDetail detail) {
    return PhotoEdit(
      category: detail.category,
      purchaseType: detail.purchaseType,
      total: detail.total,
    );
  }

  bool get showsPurchaseFields => PhotoDetail.hasPurchaseFields(category);

  /// A photo that was not an invoice has no purchase data, so moving it to
  /// «Factura» shows both fields empty to fill in (CA2).
  PhotoEdit withCategory(String? category) {
    return PhotoEdit(
      category: category,
      purchaseType: purchaseType,
      total: total,
    );
  }

  PhotoEdit withPurchase({String? purchaseType, Money? total}) {
    return PhotoEdit(
      category: category,
      purchaseType: purchaseType,
      total: total,
    );
  }

  /// What gets saved: outside «Factura» the purchase data is dropped (CA3).
  PhotoEdit toSave() {
    if (showsPurchaseFields) return this;
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
