/// Cricket overs display: [balls] = legal deliveries (e.g. 51 → 8.3).
String formatOversFromBalls(int balls) {
  if (balls <= 0) return '0.0';
  final o = balls ~/ 6;
  final b = balls % 6;
  return '$o.$b';
}

/// Strike rate: runs per 100 balls.
String formatSR(int runs, int balls) {
  if (balls == 0) return '0.0';
  return ((runs / balls) * 100).toStringAsFixed(1);
}
