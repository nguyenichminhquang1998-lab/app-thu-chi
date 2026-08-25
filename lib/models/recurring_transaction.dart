import 'transaction_entry.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final TxType type; // expense or income only
  final double amount;
  final String currency;
  final String walletId;
  final String? categoryId;
  final String note;
  final RecurrenceFrequency frequency;
  final int interval; // every N units
  final int startDate;
  final int nextDueDate;
  final int? endDate;
  final bool active;

  const RecurringTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.walletId,
    this.categoryId,
    this.note = '',
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    required this.nextDueDate,
    this.endDate,
    this.active = true,
  });

  RecurringTransaction copyWith({
    double? amount,
    String? walletId,
    String? categoryId,
    String? note,
    RecurrenceFrequency? frequency,
    int? interval,
    int? nextDueDate,
    int? endDate,
    bool? active,
  }) {
    return RecurringTransaction(
      id: id,
      type: type,
      amount: amount ?? this.amount,
      currency: currency,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      startDate: startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'currency': currency,
        'wallet_id': walletId,
        'category_id': categoryId,
        'note': note,
        'frequency': frequency.name,
        'interval_count': interval,
        'start_date': startDate,
        'next_due_date': nextDueDate,
        'end_date': endDate,
        'active': active ? 1 : 0,
      };

  factory RecurringTransaction.fromMap(Map<String, Object?> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      type: TxType.values.byName(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      walletId: map['wallet_id'] as String,
      categoryId: map['category_id'] as String?,
      note: map['note'] as String? ?? '',
      frequency: RecurrenceFrequency.values.byName(map['frequency'] as String),
      interval: map['interval_count'] as int? ?? 1,
      startDate: map['start_date'] as int,
      nextDueDate: map['next_due_date'] as int,
      endDate: map['end_date'] as int?,
      active: (map['active'] as int? ?? 1) == 1,
    );
  }

  DateTime computeNextDueDate(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(from.year, from.month, from.day + interval, from.hour, from.minute);
      case RecurrenceFrequency.weekly:
        return DateTime(from.year, from.month, from.day + 7 * interval, from.hour, from.minute);
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + interval, from.day, from.hour, from.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + interval, from.month, from.day, from.hour, from.minute);
    }
  }
}
