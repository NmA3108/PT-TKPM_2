String formatVnd(num value) {
  final negative = value < 0;
  final whole = value.abs().round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${negative ? '-' : ''}${buffer}\u0111';
}
