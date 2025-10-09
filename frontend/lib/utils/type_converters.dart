// Type conversion utilities to handle JSON parsing errors
// These helpers prevent 'type int is not a subtype of type String' errors

/// Convert any value to int safely
int toInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? defaultValue;
  }
  return defaultValue;
}

/// Convert any value to String safely
String toStr(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  if (value is String) return value;
  if (value is int || value is double) return value.toString();
  if (value is bool) return value.toString();
  return defaultValue;
}

/// Convert any value to bool safely
bool toBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
  if (value is int) return value == 1;
  return defaultValue;
}

/// Convert any value to DateTime safely
DateTime? toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Convert list of dynamic to list of strings safely
List<String> toStrList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => toStr(e)).where((e) => e.isNotEmpty).toList();
  }
  return [];
}

/// Convert list of dynamic to list of ints safely
List<int> toIntList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => toInt(e)).where((e) => e != 0).toList();
  }
  return [];
}