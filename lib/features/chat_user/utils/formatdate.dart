import 'package:intl/intl.dart';

class Formatdate {
  String formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (timestamp.isAfter(today)) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (timestamp.isAfter(yesterday)) {
      return 'เมื่อวาน';
    } else if (timestamp.year == now.year) {
      return DateFormat('d/M').format(timestamp);
    } else {
      return DateFormat('d/M/y').format(timestamp);
    }
  }
}
