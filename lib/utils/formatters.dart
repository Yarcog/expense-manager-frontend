import 'package:intl/intl.dart';

class Formatters {
  static String money(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      // El patrón fija el símbolo al inicio: el de es_CO lo pondría al final.
      customPattern: '¤#,##0',
      symbol: r'$ ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String date(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}