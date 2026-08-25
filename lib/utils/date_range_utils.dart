class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);
}

/// Computes the "budget month" range that contains [reference], given a
/// custom month-start day (1 = calendar month, e.g. 25 = 25th to 24th of
/// the next month for users paid mid-month).
DateRange monthlyPeriodFor(DateTime reference, int startDay) {
  final day = reference.day;
  late final DateTime periodStart;
  if (day >= startDay) {
    periodStart = DateTime(reference.year, reference.month, startDay);
  } else {
    periodStart = DateTime(reference.year, reference.month - 1, startDay);
  }
  final periodEndExclusive = DateTime(periodStart.year, periodStart.month + 1, periodStart.day);
  final periodEnd = periodEndExclusive.subtract(const Duration(milliseconds: 1));
  return DateRange(_startOfDay(periodStart), periodEnd);
}

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

DateRange currentMonthlyPeriod(int startDay) => monthlyPeriodFor(DateTime.now(), startDay);

DateRange shiftPeriod(DateRange range, int startDay, int direction) {
  final probe = direction > 0
      ? DateTime(range.end.year, range.end.month, range.end.day + 1)
      : DateTime(range.start.year, range.start.month, range.start.day - 1);
  return monthlyPeriodFor(probe, startDay);
}
