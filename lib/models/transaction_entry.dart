import 'category.dart';

enum TxType { expense, income, transfer }

/// Renamed from `Transaction` to `TxEntry` to avoid clashing with
/// `dart:async`'s `Transaction`-like sqflite APIs and Flutter's own
/// `Transaction` naming collisions across the data layer.
class TxEntry {
  final String id;
  final TxType type;
  final double amount;
  final String currency;
  final String walletId;
  final String? toWalletId; // only for transfers
  final String? categoryId; // null for transfers
  final int date; // millisSinceEpoch
  final String note;
  final String? tag;
  final String? photoPath;
  final String? recurringId;
  final int createdAt;

  const TxEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.walletId,
    this.toWalletId,
    this.categoryId,
    required this.date,
    this.note = '',
    this.tag,
    this.photoPath,
    this.recurringId,
    required this.createdAt,
  });

  TxEntry copyWith({
    TxType? type,
    double? amount,
    String? currency,
    String? walletId,
    String? toWalletId,
    String? categoryId,
    int? date,
    String? note,
    String? tag,
    String? photoPath,
    String? recurringId,
  }) {
    return TxEntry(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      tag: tag ?? this.tag,
      photoPath: photoPath ?? this.photoPath,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt,
    );
  }

  /// Signed amount in the wallet's own bookkeeping: expenses are negative,
  /// income positive, transfers are handled by the caller per-wallet.
  double get signedAmount => type == TxType.expense ? -amount : amount;

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'currency': currency,
        'wallet_id': walletId,
        'to_wallet_id': toWalletId,
        'category_id': categoryId,
        'date': date,
        'note': note,
        'tag': tag,
        'photo_path': photoPath,
        'recurring_id': recurringId,
        'created_at': createdAt,
      };

  factory TxEntry.fromMap(Map<String, Object?> map) {
    return TxEntry(
      id: map['id'] as String,
      type: TxType.values.byName(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      walletId: map['wallet_id'] as String,
      toWalletId: map['to_wallet_id'] as String?,
      categoryId: map['category_id'] as String?,
      date: map['date'] as int,
      note: map['note'] as String? ?? '',
      tag: map['tag'] as String?,
      photoPath: map['photo_path'] as String?,
      recurringId: map['recurring_id'] as String?,
      createdAt: map['created_at'] as int,
    );
  }
}

extension CategoryTypeMatch on TxType {
  CategoryType? get asCategoryType => switch (this) {
        TxType.expense => CategoryType.expense,
        TxType.income => CategoryType.income,
        TxType.transfer => null,
      };
}
