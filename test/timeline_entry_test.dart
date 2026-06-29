import 'package:flutter_test/flutter_test.dart';
import 'package:soloecho/models/timeline_entry.dart';

void main() {
  test('creates an entry from a sheet row', () {
    final entry = TimelineEntry.fromSheetRow(
      <Object?>['2026-06-26 13:14:15.987654', 'hello'],
    );

    expect(entry, isNotNull);
    expect(entry!.content, 'hello');
    expect(entry.timestamp.millisecond, 987);
    expect(entry.timestamp.microsecond, 654);
  });

  test('ignores incomplete rows', () {
    expect(TimelineEntry.fromSheetRow(<Object?>['Timestamp']), isNull);
  });
}
