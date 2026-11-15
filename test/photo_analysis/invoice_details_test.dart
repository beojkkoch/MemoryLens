import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/invoice_details.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/money.dart';

void main() {
  group('an amount with its currency (CA2)', () {
    String format(double amount, String currency) =>
        Money(amount: amount, currency: currency).format();

    test('dollars have cents and a dot', () {
      expect(format(23.10, 'USD'), r'$23.10');
      expect(format(1234.5, 'USD'), r'$1,234.50');
    });

    test('Colombian pesos have no cents and dot thousands', () {
      expect(format(23100, 'COP'), r'$23.100');
      expect(format(1250000, 'COP'), r'$1.250.000');
      expect(format(950, 'COP'), r'$950');
    });

    test('euros and soles use their own symbols', () {
      expect(format(1234.5, 'EUR'), '€1.234,50');
      expect(format(45.9, 'PEN'), 'S/45.90');
    });

    test('any other currency shows its code', () {
      expect(format(5000, 'PYG'), 'PYG 5000.00');
    });
  });

  group('the data of an invoice', () {
    test('only a photo in «Factura» has it (CA5)', () {
      final details = InvoiceDetails.fromPhoto(
        category: 'Comida',
        purchaseType: 'Cafetería',
        amount: 23.1,
        currency: 'USD',
      );

      expect(details, isNull);
    });

    test('the chip shows the category, the purchase and the total (CA4)', () {
      final details = InvoiceDetails.fromPhoto(
        category: 'Factura',
        purchaseType: 'Cafetería',
        amount: 23.1,
        currency: 'USD',
      );

      expect(details!.label(), r'Factura · Cafetería · $23.10');
    });

    test('what was not legible is left out, never made up (CA3)', () {
      final noAmount = InvoiceDetails.fromPhoto(
        category: 'Factura',
        purchaseType: 'Supermercado',
      );
      final noType = InvoiceDetails.fromPhoto(
        category: 'Factura',
        amount: 48900,
        currency: 'COP',
      );

      expect(noAmount!.total, isNull);
      expect(noAmount.label(), 'Factura · Supermercado');
      expect(noType!.purchaseType, isNull);
      expect(noType.label(), r'Factura · $48.900');
    });

    test('an amount without currency is not shown', () {
      final details = InvoiceDetails.fromPhoto(
        category: 'Factura',
        purchaseType: 'Farmacia',
        amount: 12,
      );

      expect(details!.total, isNull);
    });

    test('an invoice with nothing legible has no data at all', () {
      expect(
        InvoiceDetails.fromPhoto(category: 'Factura', purchaseType: '  '),
        isNull,
      );
    });
  });
}
