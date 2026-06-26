import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/workspace_info.dart';
import 'key_value_store.dart';

class SoloEchoRepository {
  SoloEchoRepository({
    required http.Client client,
    KeyValueStore? storage,
  })  : _driveApi = drive.DriveApi(client),
        _sheetsApi = sheets.SheetsApi(client),
        _storage = storage ?? JsonFileKeyValueStore.defaultStore();

  static const _folderIdKey = 'workspace_folder_id';
  static const _spreadsheetIdKey = 'workspace_spreadsheet_id';

  final drive.DriveApi _driveApi;
  final sheets.SheetsApi _sheetsApi;
  final KeyValueStore _storage;

  Future<WorkspaceInfo> ensureWorkspace() async {
    final cachedFolderId = await _storage.read(key: _folderIdKey);
    final cachedSpreadsheetId = await _storage.read(key: _spreadsheetIdKey);
    if (_hasValue(cachedFolderId) && _hasValue(cachedSpreadsheetId)) {
      return WorkspaceInfo(
        folderId: cachedFolderId!,
        spreadsheetId: cachedSpreadsheetId!,
      );
    }

    final folderId = cachedFolderId ?? await _ensureFolder();
    final spreadsheetId = cachedSpreadsheetId ??
        await _ensureSpreadsheet(
          folderId,
        );

    await _storage.write(key: _folderIdKey, value: folderId);
    await _storage.write(key: _spreadsheetIdKey, value: spreadsheetId);

    return WorkspaceInfo(folderId: folderId, spreadsheetId: spreadsheetId);
  }

  Future<void> clear() async {
    await _storage.delete(key: _folderIdKey);
    await _storage.delete(key: _spreadsheetIdKey);
  }

  Future<String> _ensureFolder() async {
    final existing = await _driveApi.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' "
          "and name = '${AppConfig.folderName}' and trashed = false",
      spaces: 'drive',
    );
    final folder =
        existing.files?.where((file) => _hasValue(file.id)).firstOrNull;
    if (folder?.id != null) {
      return folder!.id!;
    }

    final created = await _driveApi.files.create(
      drive.File()
        ..name = AppConfig.folderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    final id = created.id;
    if (!_hasValue(id)) {
      throw StateError('Could not create SoloEcho Drive folder.');
    }
    return id!;
  }

  Future<String> _ensureSpreadsheet(String folderId) async {
    final existing = await _driveApi.files.list(
      q: "mimeType = 'application/vnd.google-apps.spreadsheet' "
          "and name = '${AppConfig.spreadsheetName}' "
          "and '$folderId' in parents and trashed = false",
      spaces: 'drive',
    );
    final spreadsheet =
        existing.files?.where((file) => _hasValue(file.id)).firstOrNull;
    if (spreadsheet?.id != null) {
      await _ensureHeader(spreadsheet!.id!);
      return spreadsheet.id!;
    }

    final created = await _driveApi.files.create(
      drive.File()
        ..name = AppConfig.spreadsheetName
        ..mimeType = 'application/vnd.google-apps.spreadsheet'
        ..parents = <String>[folderId],
    );
    final spreadsheetId = created.id;
    if (!_hasValue(spreadsheetId)) {
      throw StateError('Could not create SoloEcho spreadsheet.');
    }
    await _renameFirstSheet(spreadsheetId!);
    await _ensureHeader(spreadsheetId);
    return spreadsheetId;
  }

  Future<void> _renameFirstSheet(String spreadsheetId) async {
    final spreadsheet = await _sheetsApi.spreadsheets.get(spreadsheetId);
    final sheetId = spreadsheet.sheets?.firstOrNull?.properties?.sheetId;
    if (sheetId == null) {
      return;
    }
    await _sheetsApi.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(
        requests: <sheets.Request>[
          sheets.Request(
            updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
              fields: 'title',
              properties: sheets.SheetProperties(
                sheetId: sheetId,
                title: AppConfig.logSheetName,
              ),
            ),
          ),
        ],
      ),
      spreadsheetId,
    );
  }

  Future<void> _ensureHeader(String spreadsheetId) async {
    await _sheetsApi.spreadsheets.values.update(
      sheets.ValueRange(
        values: <List<Object?>>[
          <Object?>['Timestamp', 'Content'],
        ],
      ),
      spreadsheetId,
      '${AppConfig.logSheetName}!A1:B1',
      valueInputOption: 'RAW',
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
