import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatFullDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  static String formatForFileName(DateTime date) {
    return DateFormat('yyyyMMdd_HHmmss').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == date.day) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1 || (now.day - date.day == 1 && difference.inHours < 48)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatShortDate(date);
    }
  }
}
