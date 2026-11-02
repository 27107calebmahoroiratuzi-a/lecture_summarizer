// Small helpers that turn dates, seconds and bytes into text for the screens.

const List<String> dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

// "Thu 30 Oct"
String shortDate(DateTime date) {
  final day = dayNames[date.weekday - 1].substring(0, 3);
  final month = monthNames[date.month - 1].substring(0, 3);
  return '$day ${date.day} $month';
}

// "Thursday, 30 October 2026"
String longDate(DateTime date) {
  final day = dayNames[date.weekday - 1];
  final month = monthNames[date.month - 1];
  return '$day, ${date.day} $month ${date.year}';
}

// "OCTOBER 2026"
String monthLabel(DateTime date) {
  return '${monthNames[date.month - 1].toUpperCase()} ${date.year}';
}

// 1477 -> "24:37"
String clock(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  String twoDigits(int n) {
    if (n < 10) {
      return '0$n';
    }
    return '$n';
  }

  return '${twoDigits(minutes)}:${twoDigits(rest)}';
}

// 3480 -> "58 min". Imported files have no known length (0 seconds).
String minutesText(int seconds) {
  if (seconds == 0) {
    return 'imported audio';
  }
  if (seconds < 60) {
    return '$seconds sec';
  }
  return '${(seconds / 60).round()} min';
}

// 6100000 -> "6.1 MB"
String megabytes(int bytes) {
  final mb = bytes / 1000000;
  return '${mb.toStringAsFixed(1)} MB';
}
