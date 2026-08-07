double roundAmount(double value) => (value * 100).roundToDouble() / 100;

String formatAmount(double value) {
  final rounded = roundAmount(value);
  if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
  return rounded
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
