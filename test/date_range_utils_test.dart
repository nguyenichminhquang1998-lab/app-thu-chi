import 'package:app_thu_chi/utils/date_range_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monthlyPeriodFor', () {
    test('calendar month when startDay is 1', () {
      final range = monthlyPeriodFor(DateTime(2026, 8, 15), 1);
      expect(range.start, DateTime(2026, 8, 1));
      expect(range.end.year, 2026);
      expect(range.end.month, 8);
      expect(range.end.day, 31);
    });

    test('custom start day before the day rolls back to previous month', () {
      final range = monthlyPeriodFor(DateTime(2026, 8, 10), 25);
      expect(range.start, DateTime(2026, 7, 25));
      expect(range.end.month, 8);
      expect(range.end.day, 24);
    });

    test('custom start day after the day stays in current month', () {
      final range = monthlyPeriodFor(DateTime(2026, 8, 30), 25);
      expect(range.start, DateTime(2026, 8, 25));
      expect(range.end.month, 9);
      expect(range.end.day, 24);
    });
  });

  group('shiftPeriod', () {
    test('moving forward lands on the next period', () {
      final current = monthlyPeriodFor(DateTime(2026, 8, 15), 1);
      final next = shiftPeriod(current, 1, 1);
      expect(next.start, DateTime(2026, 9, 1));
    });

    test('moving backward lands on the previous period', () {
      final current = monthlyPeriodFor(DateTime(2026, 8, 15), 1);
      final previous = shiftPeriod(current, 1, -1);
      expect(previous.start, DateTime(2026, 7, 1));
    });
  });
}
