class TimestampFormatter {
  TimestampFormatter._();

  static final RegExp _localFormat = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2}) '
    r'(\d{2}):(\d{2}):(\d{2})\.(\d{3})(\d{3})?$',
  );

  static String format(DateTime value) {
    final local = value.toLocal();
    final date = '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
    final fractional = '${local.millisecond.toString().padLeft(3, '0')}'
        '${local.microsecond.toString().padLeft(3, '0')}';
    return '$date $time.$fractional';
  }

  static DateTime? tryParse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final match = _localFormat.firstMatch(trimmed);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);
      final millisecond = int.parse(match.group(7)!);
      final microsecond = int.parse(match.group(8) ?? '0');
      final parsed = DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );
      if (parsed.year == year &&
          parsed.month == month &&
          parsed.day == day &&
          parsed.hour == hour &&
          parsed.minute == minute &&
          parsed.second == second &&
          parsed.millisecond == millisecond &&
          parsed.microsecond == microsecond) {
        return parsed;
      }
      return null;
    }
    try {
      return DateTime.parse(trimmed).toLocal();
    } on FormatException {
      return null;
    }
  }
}
