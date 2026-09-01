import 'package:intl/intl.dart';

String formatBdt(num amount) {
  final f = NumberFormat.currency(
    locale: 'en_BD',
    symbol: '৳ ',
    decimalDigits: 2,
  );
  return f.format(amount);
}
