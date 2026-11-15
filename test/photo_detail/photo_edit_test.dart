import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';

void main() {
  const cafe = Money(amount: 23100, currency: 'COP');

  final invoice = PhotoEdit.from(
    const PhotoDetail(
      id: 'f1',
      category: 'Factura',
      purchaseType: 'Cafetería',
      total: cafe,
    ),
  );

  group('the fields of each category (HU-29)', () {
    test('only an invoice has purchase fields (CA1)', () {
      expect(PhotoDetail.hasPurchaseFields('Factura'), isTrue);
      expect(PhotoDetail.hasPurchaseFields('Lugar'), isFalse);
      expect(PhotoDetail.hasPurchaseFields(null), isFalse);
      expect(invoice.showsPurchaseFields, isTrue);
    });

    test('a landscape moved to «Factura» shows both fields empty (CA2)', () {
      final landscape = PhotoEdit.from(
        const PhotoDetail(id: 'f2', category: 'Lugar'),
      );

      final edit = landscape.withCategory('Factura');

      expect(edit.showsPurchaseFields, isTrue);
      expect(edit.purchaseType, isNull);
      expect(edit.total, isNull);
    });

    test('the empty fields can be filled in (CA2)', () {
      final edit = const PhotoEdit(category: 'Lugar')
          .withCategory('Factura')
          .withPurchase(purchaseType: 'Mercado', total: cafe);

      expect(
        edit.toSave(),
        const PhotoEdit(
          category: 'Factura',
          purchaseType: 'Mercado',
          total: cafe,
        ),
      );
    });

    test('another category hides them but keeps the values (CA3)', () {
      final edit = invoice.withCategory('Comida');

      expect(edit.showsPurchaseFields, isFalse);
      expect(edit.purchaseType, 'Cafetería');
      expect(edit.total, cafe);
    });

    test('going back to «Factura» before saving loses nothing (CA3)', () {
      final edit = invoice.withCategory('Comida').withCategory('Factura');

      expect(edit.toSave(), invoice);
    });

    test('the values are cleared only when saving (CA3)', () {
      expect(
        invoice.withCategory('Comida').toSave(),
        const PhotoEdit(category: 'Comida'),
      );
    });
  });
}
