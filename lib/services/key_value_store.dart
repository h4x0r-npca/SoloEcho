import 'dart:convert';
import 'dart:io';

abstract class KeyValueStore {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String? value});

  Future<void> delete({required String key});
}

class JsonFileKeyValueStore implements KeyValueStore {
  JsonFileKeyValueStore._(this._file);

  factory JsonFileKeyValueStore.defaultStore() {
    final appData = Platform.environment['APPDATA'];
    if (Platform.isWindows && appData != null && appData.trim().isNotEmpty) {
      return JsonFileKeyValueStore._(
        File('$appData${Platform.pathSeparator}SoloEcho'
            '${Platform.pathSeparator}settings.json'),
      );
    }
    final home = Platform.environment['HOME'];
    if (Platform.isMacOS && home != null && home.trim().isNotEmpty) {
      return JsonFileKeyValueStore._(
        File('$home${Platform.pathSeparator}Library'
            '${Platform.pathSeparator}Application Support'
            '${Platform.pathSeparator}SoloEcho'
            '${Platform.pathSeparator}settings.json'),
      );
    }
    return JsonFileKeyValueStore._(
      File('${Directory.systemTemp.path}${Platform.pathSeparator}SoloEcho'
          '${Platform.pathSeparator}settings.json'),
    );
  }

  final File _file;

  @override
  Future<String?> read({required String key}) async {
    final values = await _readAll();
    return values[key];
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      await delete(key: key);
      return;
    }
    final values = await _readAll();
    values[key] = value;
    await _writeAll(values);
  }

  @override
  Future<void> delete({required String key}) async {
    final values = await _readAll();
    values.remove(key);
    await _writeAll(values);
  }

  Future<Map<String, String>> _readAll() async {
    if (!await _file.exists()) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return <String, String>{};
      }
      return decoded.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
    } on FormatException {
      return <String, String>{};
    } on FileSystemException {
      return <String, String>{};
    }
  }

  Future<void> _writeAll(Map<String, String> values) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(values));
  }
}
