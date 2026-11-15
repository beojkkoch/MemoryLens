import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_detail.dart';
import 'package:memorylens/features/photo_detail/domain/entities/photo_edit.dart';

// How the detail hides and shows these fields while editing (HU-29, CA2 and
// CA3) is tested on the screen, in photo_detail_test.dart.
void main() {
  const cafe = Money(amount: 23100, currency: 'COP');

  group('the fields of each category (HU-29)', () {
    test('only an invoice has purchase fields (CA1)', () {
      expect(PhotoDetail.hasPurchaseFields('Factura'), isTrue);
      expect(PhotoDetail.hasPurchaseFields('Lugar'), isFalse);
      expect(PhotoDetail.hasPurchaseFields(null), isFalse);
    });

    test('an invoice is saved with its purchase data', () {
      const edit = PhotoEdit(
        category: 'Factura',
        purchaseType: 'Cafetería',
        total: cafe,
      );

      expect(edit.toSave(), edit);
    });

    test('another category drops the purchase data when saving (CA3)', () {
      const edit = PhotoEdit(
        category: 'Comida',
        purchaseType: 'Cafetería',
        total: cafe,
      );

      expect(edit.toSave(), const PhotoEdit(category: 'Comida'));
    });

    test('so does a photo with no category', () {
      const edit = PhotoEdit(purchaseType: 'Cafetería', total: cafe);

      expect(edit.toSave(), const PhotoEdit());
    });
  });
}
