class DateTimeFormatter {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  /// Parses ISO string, DateTime, or time string (e.g. "09:00" or ISO 8601) into DateTime
  static DateTime? parseDateTime(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input.toLocal();
    if (input is String) {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return null;
      try {
        return DateTime.parse(trimmed).toLocal();
      } catch (_) {
        if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(trimmed)) {
          final parts = trimmed.split(':').map(int.parse).toList();
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, parts[0], parts[1]);
        }
      }
    }
    return null;
  }

  /// Formats date to user-friendly string, e.g. "05 Sep 2026"
  static String formatDate(dynamic input, {String fallback = ''}) {
    final dt = parseDateTime(input);
    if (dt == null) {
      if (input is String && input.length >= 10 && !input.contains('T')) {
        return input;
      }
      return fallback;
    }
    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    return '$day $month ${dt.year}';
  }

  /// Formats time to 12-hour AM/PM string, e.g. "09:00 AM"
  static String formatTime(dynamic input, {String fallback = ''}) {
    if (input is String && RegExp(r'^\d{1,2}:\d{2}$').hasMatch(input.trim())) {
      final parts = input.trim().split(':').map(int.parse).toList();
      final hour = parts[0];
      final min = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      final minStr = min.toString().padLeft(2, '0');
      return '${h12.toString().padLeft(2, '0')}:$minStr $period';
    }

    final dt = parseDateTime(input);
    if (dt == null) return fallback;

    final hour = dt.hour;
    final min = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final minStr = min.toString().padLeft(2, '0');
    return '${h12.toString().padLeft(2, '0')}:$minStr $period';
  }

  /// Formats date and time, e.g. "05 Sep 2026, 09:00 AM"
  static String formatDateTime(dynamic input, {String fallback = ''}) {
    final dt = parseDateTime(input);
    if (dt == null) return fallback;
    return '${formatDate(dt)}, ${formatTime(dt)}';
  }

  /// Formats time range cleanly, e.g. "09:00 AM - 10:00 AM"
  static String formatTimeRange(dynamic startInput, dynamic endInput) {
    final formattedStart = formatTime(startInput);
    final formattedEnd = formatTime(endInput);
    if (formattedStart.isNotEmpty && formattedEnd.isNotEmpty) {
      return '$formattedStart - $formattedEnd';
    }
    return '${startInput ?? ""} - ${endInput ?? ""}';
  }
}
