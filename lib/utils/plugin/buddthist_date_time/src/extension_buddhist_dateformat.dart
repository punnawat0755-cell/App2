import 'package:intl/intl.dart';

extension BuddhistDateFormat on DateFormat {
  String formatInBuddhistCalendarThai(DateTime date) {
    if (pattern == 'HH:mm') {
      return DateFormat('HH:mm', locale).format(date);
    }

    final buddhistYear = date.year + 543;
    final dayMonth = DateFormat('dd/MM', locale).format(date);
    return '$dayMonth/$buddhistYear';
  }
}
