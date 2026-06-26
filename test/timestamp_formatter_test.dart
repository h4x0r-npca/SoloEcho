import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/utils/timestamp_formatter.dart';

void main() {
  test('formats timestamps with milliseconds', () {
    final timestamp = DateTime(2026, 6, 26, 13, 14, 15, 987);

    expect(
      TimestampFormatter.format(timestamp),
      '2026-06-26 13:14:15.987',
    );
  });

  test('parses formatted timestamps', () {
    final parsed = TimestampFormatter.tryParse('2026-06-26 13:14:15.987');

    expect(parsed, isNotNull);
    expect(parsed!.millisecond, 987);
  });
}
