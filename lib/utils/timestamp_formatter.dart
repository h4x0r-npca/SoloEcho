import 'package:intl/intl.dart';

class TimestampFormatter {
  TimestampFormatter._();

  static final DateFormat _sheetFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  static String format(DateTime value) {
    return _sheetFormat.format(value.toLocal());
  }

  static DateTime? tryParse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return _sheetFormat.parseStrict(trimmed);
    } on FormatException {
      try {
        return DateTime.parse(trimmed).toLocal();
      } on FormatException {
        return null;
      }
    }
  }
}
