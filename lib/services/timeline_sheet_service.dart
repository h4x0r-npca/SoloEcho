import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/timeline_entry.dart';

class TimelineSheetService {
  TimelineSheetService({
    required http.Client client,
    required this.spreadsheetId,
  }) : _sheetsApi = sheets.SheetsApi(client);

  final sheets.SheetsApi _sheetsApi;
  final String spreadsheetId;

  Future<TimelineEntry> appendEntry(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(content, 'content', 'Content cannot be empty.');
    }
    final entry = TimelineEntry(
      timestamp: DateTime.now(),
      content: trimmed,
    );
    await _sheetsApi.spreadsheets.values.append(
      sheets.ValueRange(values: <List<Object?>>[entry.toSheetRow()]),
      spreadsheetId,
      '${AppConfig.logSheetName}!A:B',
      insertDataOption: 'INSERT_ROWS',
      valueInputOption: 'RAW',
    );
    return entry;
  }

  Future<List<TimelineEntry>> readEntriesNewestFirst() async {
    final response = await _sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      '${AppConfig.logSheetName}!A2:B',
    );
    final values = response.values ?? const <List<Object?>>[];
    return values
        .map(TimelineEntry.fromSheetRow)
        .whereType<TimelineEntry>()
        .toList()
        .reversed
        .toList(growable: true);
  }
}
