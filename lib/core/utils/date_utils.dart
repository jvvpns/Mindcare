import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  // ── Formatters ────────────────────────────────────────────────────────────
  static String formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('h:mm a').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('MMM d, yyyy · h:mm a').format(date);

  static String formatDayMonth(DateTime date) =>
      DateFormat('MMM d').format(date);

  static String formatWeekday(DateTime date) =>
      DateFormat('EEE').format(date);             // Mon, Tue...

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static String formatIso(DateTime date) =>
      date.toIso8601String();

  // ── Relative Labels ───────────────────────────────────────────────────────
  static String relativeLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return '$diff days ago';
    return formatDate(date);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return relativeLabel(date);
  }

  // ── Checks ────────────────────────────────────────────────────────────────
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final target = DateTime(date.year, date.month, date.day);
    return !target.isBefore(start) && !target.isAfter(DateTime(now.year, now.month, now.day));
  }

  // ── Week Helpers ─────────────────────────────────────────────────────────
  /// Returns the last N days starting from today, most recent last
  static List<DateTime> lastNDays(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) {
      final d = now.subtract(Duration(days: n - 1 - i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  /// Returns Monday–Sunday of the week containing [date]
  static List<DateTime> weekOf(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  // ── Start of Day ──────────────────────────────────────────────────────────
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  // ── Greeting ─────────────────────────────────────────────────────────────
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}