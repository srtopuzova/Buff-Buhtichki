import 'package:intl/intl.dart';

class DateHelpers {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');

  static String formatDisplay(DateTime date) => _displayFormat.format(date);
  static String formatShort(DateTime date) => _shortFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  static int daysUntilExpiry(DateTime expiry) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryDay.difference(today).inDays;
  }

  static bool isExpired(DateTime expiry) => daysUntilExpiry(expiry) < 0;

  static bool isExpiringSoon(DateTime expiry, {int withinDays = 30}) {
    final days = daysUntilExpiry(expiry);
    return days >= 0 && days <= withinDays;
  }

  static String expiryLabel(DateTime expiry) {
    final days = daysUntilExpiry(expiry);
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    if (days <= 30) return 'Expires in $days days';
    return 'Expires ${formatDisplay(expiry)}';
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDisplay(date);
  }

  static DateTime? tryParseExpiry(String raw) {
    // Try MM/YYYY
    final mmYYYY = RegExp(r'^(\d{1,2})[/\-\.](\d{4})$');
    final m1 = mmYYYY.firstMatch(raw.trim());
    if (m1 != null) {
      final month = int.tryParse(m1.group(1)!);
      final year = int.tryParse(m1.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        // Last day of that month
        final firstOfNext = DateTime(year, month + 1, 1);
        return firstOfNext.subtract(const Duration(days: 1));
      }
    }
    // Try DD/MM/YYYY
    final ddMMYYYY = RegExp(r'^(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})$');
    final m2 = ddMMYYYY.firstMatch(raw.trim());
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!);
      final month = int.tryParse(m2.group(2)!);
      final year = int.tryParse(m2.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    // Try standard DateTime.parse
    return DateTime.tryParse(raw.trim());
  }
}
