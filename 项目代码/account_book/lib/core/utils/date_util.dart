class DateUtil {
  DateUtil._();

  static String formatDate(DateTime date) {
    return '${date.year}-${pad(date.month)}-${pad(date.day)}';
  }

  static String formatMonth(int year, int month) {
    return '$year-${pad(month)}';
  }

  static String formatWeekday(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${weekdays[date.weekday - 1]}';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime startOfMonth(int year, int month) {
    return DateTime(year, month, 1);
  }

  static DateTime endOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }

  static String formatDateTime(DateTime dt) {
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  static String pad(int n) => n.toString().padLeft(2, '0');
}
