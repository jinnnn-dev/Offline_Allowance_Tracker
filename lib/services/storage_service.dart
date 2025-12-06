import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/allowance.dart';
import '../models/savings_entry.dart';

class StorageService {
  static const String _allowanceKey = 'allowance';
  static const String _expensesKey = 'expenses';
  static const String _savingsKey = 'savings';
  static const String _savingsTargetKey = 'savings_targets';
  static const String _lastSavingsReminderKey = 'last_savings_reminder';

  static Future<void> saveAllowance(Allowance allowance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_allowanceKey, jsonEncode(allowance.toJson()));
  }

  static Future<Allowance?> getallowance() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_allowanceKey);
    if (jsonString == null) return null;
    final allowance = Allowance.fromJson(jsonDecode(jsonString));

    // Auto-reset logic: if frequency is daily and lastResetDate is before today,
    // or if frequency is weekly and lastResetDate is before the start of the current week,
    // update the stored allowance's lastResetDate so the app treats the allowance as reset.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool needsReset = false;
    DateTime newResetDate = allowance.lastResetDate;

    if (allowance.frequency == AllowanceFrequency.daily) {
      if (!_isSameDay(allowance.lastResetDate, today)) {
        needsReset = true;
        newResetDate = today;
      }
    } else {
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1)); // Monday as start
      final lastReset = DateTime(
        allowance.lastResetDate.year,
        allowance.lastResetDate.month,
        allowance.lastResetDate.day,
      );
      if (lastReset.isBefore(startOfWeek)) {
        needsReset = true;
        newResetDate = startOfWeek;
      }
    }

    if (needsReset) {
      final updated = Allowance(
        amount: allowance.amount,
        frequency: allowance.frequency,
        lastResetDate: newResetDate,
      );
      await saveAllowance(updated);
      return updated;
    }

    return allowance;
  }

  static Future<void> saveExpense(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final expenses = await getAllExpenses();
    expenses.add(expense);
    await prefs.setString(
      _expensesKey,
      jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<Expense>> getAllExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_expensesKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => Expense.fromJson(e)).toList();
  }

  static Future<void> deleteExpense(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final expenses = await getAllExpenses();
    expenses.removeWhere((e) => e.id == id);
    await prefs.setString(
      _expensesKey,
      jsonEncode(expenses.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> updateExpense(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final expenses = await getAllExpenses();
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      expenses[index] = expense;
      await prefs.setString(
        _expensesKey,
        jsonEncode(expenses.map((e) => e.toJson()).toList()),
      );
    }
  }

  static Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final expenses = await getAllExpenses();
    return expenses.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  static Future<double> getTodayTotalSpent() async {
    final expenses = await getExpensesByDate(DateTime.now());
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  static Future<List<Expense>> getRecentExpenses({int limit = 3}) async {
    final expenses = await getAllExpenses();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    if (expenses.length <= limit) {
      return expenses;
    }
    return expenses.sublist(0, limit);
  }

  static Future<List<SavingsEntry>> getSavingsEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_savingsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => SavingsEntry.fromJson(e)).toList();
  }

  static Future<Map<String, double>> getAllSavingsTargets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_savingsTargetKey);
    if (jsonString == null) return {};
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  static Future<double?> getSavingsTargetForMonth(DateTime date) async {
    final targets = await getAllSavingsTargets();
    return targets[_monthKey(date)];
  }

  static Future<void> saveSavingsTarget(DateTime date, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final targets = await getAllSavingsTargets();
    targets[_monthKey(date)] = amount;
    await prefs.setString(_savingsTargetKey, jsonEncode(targets));
  }

  static Future<void> deleteSavingsTarget(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final targets = await getAllSavingsTargets();
    targets.remove(_monthKey(date));
    if (targets.isEmpty) {
      await prefs.remove(_savingsTargetKey);
    } else {
      await prefs.setString(_savingsTargetKey, jsonEncode(targets));
    }
  }

  static Future<void> saveSavingsEntry(SavingsEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getSavingsEntries();
    entries.removeWhere((e) => e.date.year == entry.date.year && e.date.month == entry.date.month && e.date.day == entry.date.day);
    entries.add(entry);
    entries.sort((a, b) => b.date.compareTo(a.date));
    await prefs.setString(
      _savingsKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  static Future<bool> hasSavingsEntryForDate(DateTime date) async {
    final entries = await getSavingsEntries();
    return entries.any((entry) => _isSameDay(entry.date, date));
  }

  static Future<double> getTotalSavedAmount() async {
    final entries = await getSavingsEntries();
    return entries
        .where((entry) => entry.isSaved)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  static Future<void> setLastSavingsReminderDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSavingsReminderKey, date.toIso8601String());
  }

  static Future<DateTime?> getLastSavingsReminderDate() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastSavingsReminderKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static String _monthKey(DateTime date) {
    final normalized = DateTime(date.year, date.month);
    return '${normalized.year.toString().padLeft(4, '0')}-${normalized.month.toString().padLeft(2, '0')}';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
