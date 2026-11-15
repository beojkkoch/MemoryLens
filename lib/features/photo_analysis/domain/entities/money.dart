/// An amount with its currency, as the AI read it from an invoice (HU-09).
class Money {
  final double amount;

  /// ISO 4217 code, such as COP or USD.
  final String currency;

  const Money({required this.amount, required this.currency});

  /// How each currency is usually written. Any other one shows its code.
  static const _styles = {
    'USD': _Style(r'$', 2, ',', '.'),
    'CAD': _Style(r'CA$', 2, ',', '.'),
    'MXN': _Style(r'$', 2, ',', '.'),
    'COP': _Style(r'$', 0, '.', ','),
    'CLP': _Style(r'$', 0, '.', ','),
    'ARS': _Style(r'$', 2, '.', ','),
    'UYU': _Style(r'$U', 2, '.', ','),
    'PEN': _Style('S/', 2, ',', '.'),
    'BRL': _Style(r'R$', 2, '.', ','),
    'EUR': _Style('€', 2, '.', ','),
    'GBP': _Style('£', 2, ',', '.'),
  };

  /// The amount as people read it: `$23.10` in dollars, `$23.100` in
  /// Colombian pesos, `€1.234,50` in euros, `PYG 5000.00` for the rest.
  String format() {
    final style = _styles[currency];
    if (style == null) return '$currency ${amount.toStringAsFixed(2)}';

    final fixed = amount.abs().toStringAsFixed(style.decimals);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => style.thousands,
    );
    final number = parts.length > 1
        ? '$whole${style.decimal}${parts[1]}'
        : whole;
    return '${amount < 0 ? '-' : ''}${style.symbol}$number';
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => 'Money($amount $currency)';
}

class _Style {
  final String symbol;
  final int decimals;
  final String thousands;
  final String decimal;

  const _Style(this.symbol, this.decimals, this.thousands, this.decimal);
}
