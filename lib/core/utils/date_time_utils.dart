import 'package:intl/intl.dart';
import 'package:leave_management/core/constants/app_constants.dart';

class DateTimeUtils {
  static String formatDate(DateTime date, {String? format}) {
    return DateFormat(format ?? AppConstants.displayDateFormat).format(date.toLocal());
  }
  
  static String formatTime(DateTime time, {String? format}) {
    return DateFormat(format ?? AppConstants.displayTimeFormat).format(time.toLocal());
  }
  
  static String formatDateTime(DateTime dateTime, {String? format}) {
    return DateFormat(format ?? AppConstants.dateTimeFormat).format(dateTime.toLocal());
  }
  
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
  
  static Duration calculateDuration(DateTime start, DateTime end) {
    return end.difference(start);
  }
  
  static String durationToString(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
  
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }
  
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
  
  static String getRelativeDate(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isYesterday(date)) return 'Yesterday';
    return formatDate(date);
  }
}
