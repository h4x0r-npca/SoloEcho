import '../utils/timestamp_formatter.dart';

class TimelineEntry {
  const TimelineEntry({
    required this.timestamp,
    required this.content,
  });

  final DateTime timestamp;
  final String content;

  String get formattedTimestamp => TimestampFormatter.format(timestamp);

  List<Object?> toSheetRow() => <Object?>[
        TimestampFormatter.format(timestamp),
        content,
      ];

  static TimelineEntry? fromSheetRow(List<Object?> row) {
    if (row.length < 2) {
      return null;
    }
    final rawTimestamp = row[0]?.toString() ?? '';
    final rawContent = row[1]?.toString() ?? '';
    final timestamp = TimestampFormatter.tryParse(rawTimestamp);
    if (timestamp == null || rawContent.isEmpty) {
      return null;
    }
    return TimelineEntry(timestamp: timestamp, content: rawContent);
  }
}
