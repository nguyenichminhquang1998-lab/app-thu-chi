import 'package:intl/intl.dart';

final _amountFormat = NumberFormat.decimalPattern('vi_VN');
final _dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN');
final _dateShortFormat = DateFormat('d/M/yy', 'vi_VN');
final _weekdayDateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');
final _timeFormat = DateFormat('HH:mm', 'vi_VN');

/// Formats an amount using Vietnamese grouping (dot as thousands
/// separator), e.g. 1234567 -> "1.234.567".
String formatAmount(num amount) => _amountFormat.format(amount);

String formatCurrency(num amount, {String currency = 'VND', bool withSign = false}) {
  final sign = withSign && amount > 0 ? '+' : '';
  final body = formatAmount(amount);
  return currency == 'VND' ? '$sign$body₫' : '$sign$body $currency';
}

String formatDate(DateTime date) => _dateFormat.format(date);
String formatDateShort(DateTime date) => _dateShortFormat.format(date);
String formatWeekdayDate(DateTime date) => _weekdayDateFormat.format(date);
String formatTime(DateTime date) => _timeFormat.format(date);

String formatDateRange(DateTime start, DateTime end) =>
    '${formatDateShort(start)} - ${formatDateShort(end)}';
