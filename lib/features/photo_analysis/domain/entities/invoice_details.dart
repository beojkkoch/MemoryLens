import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';

/// What the AI read from a photo classified as «Factura» (HU-09): the kind of
/// purchase and the total. Either can be missing when it was not legible.
class InvoiceDetails {
  /// The name of the category, as in the categoria table.
  static const category = 'Factura';

  /// For example «Cafetería».
  final String? purchaseType;

  final Money? total;

  const InvoiceDetails({this.purchaseType, this.total});

  /// Builds the details from the columns of a photo. Only a photo in the
  /// «Factura» category has them (CA5), and one without any legible data has
  /// none, so the screen shows nothing instead of an empty card.
  static InvoiceDetails? fromPhoto({
    required String? category,
    String? purchaseType,
    num? amount,
    String? currency,
  }) {
    if (category != InvoiceDetails.category) return null;
    final type = purchaseType?.trim();
    final total = amount != null && amount > 0 && currency != null
        ? Money(amount: amount.toDouble(), currency: currency)
        : null;
    if ((type == null || type.isEmpty) && total == null) return null;
    return InvoiceDetails(
      purchaseType: type == null || type.isEmpty ? null : type,
      total: total,
    );
  }

  /// The chip of the photo, for example «Factura · Cafetería · $23.10». The
  /// parts that were not legible are left out.
  String label() {
    return [category, ?purchaseType, ?total?.format()].join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      other is InvoiceDetails &&
      other.purchaseType == purchaseType &&
      other.total == total;

  @override
  int get hashCode => Object.hash(purchaseType, total);

  @override
  String toString() => 'InvoiceDetails($purchaseType, $total)';
}
