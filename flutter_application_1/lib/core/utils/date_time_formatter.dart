import 'package:intl/intl.dart';

class DateTimeFormatter {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayNameFormat = DateFormat('EEEE');

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _dateFormat.format(dateTime);
  }

  static String formatShortDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _shortDateFormat.format(dateTime);
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return _timeFormat.format(dateTime);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatMonthYear(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _monthYearFormat.format(dateTime);
  }

  static String formatDayName(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _dayNameFormat.format(dateTime);
  }

  static String formatDuration(Duration? duration) {
    if (duration == null || duration.inMinutes == 0) return '--';
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '${minutes}m';
    }
    return '${hours}h ${minutes}m';
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }
}
