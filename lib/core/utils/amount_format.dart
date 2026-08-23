double roundAmount(double value) => (value * 100).roundToDouble() / 100;

String formatMinutes(double value) {
  final total = value.round();
  final hours = total ~/ 60;
  final minutes = total % 60;
  if (hours == 0) return '${minutes}m';
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}

String formatAmount(double value) {
  final rounded = roundAmount(value);
  if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
  return rounded
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
