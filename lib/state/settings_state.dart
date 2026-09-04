import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How large amounts are displayed on summary screens — mirrors the
/// reference app's "Hiển thị Đơn vị Tiền tệ" setting.
enum AmountDisplayUnit { full, thousand, million }

class SettingsState extends ChangeNotifier {
  static const _kThemeMode = 'theme_mode';
  static const _kMonthStartDay = 'month_start_day';
  static const _kBudgetModeEnabled = 'budget_mode_enabled';
  static const _kAmountUnit = 'amount_display_unit';
  static const _kReminderEnabled = 'reminder_enabled';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderMinute = 'reminder_minute';
  static const _kLockEnabled = 'lock_enabled';
  static const _kPinHash = 'pin_hash';
  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kBalanceHidden = 'balance_hidden';
  static const _kBaseCurrency = 'base_currency';
  static const _kExchangeRates = 'exchange_rates_json';
  static const _kLastBackupAt = 'last_backup_at';
  static const _kInstallHintDismissed = 'install_hint_dismissed';

  SharedPreferences? _prefs;

  ThemeMode themeMode = ThemeMode.system;
  int monthStartDay = 1;
  bool budgetModeEnabled = true;
  AmountDisplayUnit amountDisplayUnit = AmountDisplayUnit.full;
  bool reminderEnabled = false;
  int reminderHour = 20;
  int reminderMinute = 0;
  bool lockEnabled = false;
  String? pinHash;
  bool biometricEnabled = false;
  bool balanceHidden = false;
  String baseCurrency = 'VND';
  Map<String, double> exchangeRates = {'VND': 1.0};

  /// When the user last exported a backup. Browser storage can be wiped by
  /// the browser itself, so the web build nags gently when this gets stale.
  DateTime? lastBackupAt;
  bool installHintDismissed = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    themeMode = ThemeMode.values[prefs.getInt(_kThemeMode) ?? ThemeMode.system.index];
    monthStartDay = prefs.getInt(_kMonthStartDay) ?? 1;
    budgetModeEnabled = prefs.getBool(_kBudgetModeEnabled) ?? true;
    amountDisplayUnit = AmountDisplayUnit.values[prefs.getInt(_kAmountUnit) ?? 0];
    reminderEnabled = prefs.getBool(_kReminderEnabled) ?? false;
    reminderHour = prefs.getInt(_kReminderHour) ?? 20;
    reminderMinute = prefs.getInt(_kReminderMinute) ?? 0;
    lockEnabled = prefs.getBool(_kLockEnabled) ?? false;
    pinHash = prefs.getString(_kPinHash);
    biometricEnabled = prefs.getBool(_kBiometricEnabled) ?? false;
    balanceHidden = prefs.getBool(_kBalanceHidden) ?? false;
    baseCurrency = prefs.getString(_kBaseCurrency) ?? 'VND';
    final ratesJson = prefs.getString(_kExchangeRates);
    if (ratesJson != null) {
      final decoded = jsonDecode(ratesJson) as Map<String, dynamic>;
      exchangeRates = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    final backupMillis = prefs.getInt(_kLastBackupAt);
    lastBackupAt = backupMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(backupMillis);
    installHintDismissed = prefs.getBool(_kInstallHintDismissed) ?? false;
    notifyListeners();
  }

  Future<void> markBackedUp() async {
    lastBackupAt = DateTime.now();
    await _prefs?.setInt(_kLastBackupAt, lastBackupAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> dismissInstallHint() async {
    installHintDismissed = true;
    await _prefs?.setBool(_kInstallHintDismissed, true);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs?.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setMonthStartDay(int day) async {
    monthStartDay = day;
    await _prefs?.setInt(_kMonthStartDay, day);
    notifyListeners();
  }

  Future<void> setBudgetModeEnabled(bool enabled) async {
    budgetModeEnabled = enabled;
    await _prefs?.setBool(_kBudgetModeEnabled, enabled);
    notifyListeners();
  }

  Future<void> setAmountDisplayUnit(AmountDisplayUnit unit) async {
    amountDisplayUnit = unit;
    await _prefs?.setInt(_kAmountUnit, unit.index);
    notifyListeners();
  }

  Future<void> setReminder({required bool enabled, int? hour, int? minute}) async {
    reminderEnabled = enabled;
    if (hour != null) reminderHour = hour;
    if (minute != null) reminderMinute = minute;
    await _prefs?.setBool(_kReminderEnabled, enabled);
    await _prefs?.setInt(_kReminderHour, reminderHour);
    await _prefs?.setInt(_kReminderMinute, reminderMinute);
    notifyListeners();
  }

  Future<void> setLock({required bool enabled, String? newPinHash, bool? biometric}) async {
    lockEnabled = enabled;
    if (newPinHash != null) pinHash = newPinHash;
    if (biometric != null) biometricEnabled = biometric;
    await _prefs?.setBool(_kLockEnabled, enabled);
    if (pinHash != null) await _prefs?.setString(_kPinHash, pinHash!);
    await _prefs?.setBool(_kBiometricEnabled, biometricEnabled);
    notifyListeners();
  }

  Future<void> setBalanceHidden(bool hidden) async {
    balanceHidden = hidden;
    await _prefs?.setBool(_kBalanceHidden, hidden);
    notifyListeners();
  }

  Future<void> setExchangeRate(String currency, double rateToBase) async {
    exchangeRates = {...exchangeRates, currency: rateToBase};
    await _prefs?.setString(_kExchangeRates, jsonEncode(exchangeRates));
    notifyListeners();
  }

  Future<void> setBaseCurrency(String currency) async {
    baseCurrency = currency;
    await _prefs?.setString(_kBaseCurrency, currency);
    notifyListeners();
  }

  /// Converts an amount from [currency] into the base currency for
  /// aggregated totals. Rates are manually maintained (offline-friendly);
  /// unknown currencies fall back to a 1:1 rate.
  double convertToBase(double amount, String currency) {
    if (currency == baseCurrency) return amount;
    final rate = exchangeRates[currency] ?? 1.0;
    return amount * rate;
  }
}
