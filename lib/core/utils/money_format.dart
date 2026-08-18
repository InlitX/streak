import 'dart:ui';

import 'package:intl/intl.dart';

const currencySymbols = [
  '€',
  '\$',
  '£',
  '¥',
  '₹',
  'R\$',
  'kr',
  'zł',
  '₺',
  '₽',
  '₩',
  'CHF',
];

String defaultCurrencySymbol() {
  try {
    return NumberFormat.simpleCurrency(
      locale: PlatformDispatcher.instance.locale.toString(),
    ).currencySymbol;
  } catch (_) {
    return '€';
  }
}

String formatMoney(double value, String symbol, String locale) =>
    NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: value == value.roundToDouble() ? 0 : 2,
    ).format(value);
