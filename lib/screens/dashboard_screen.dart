import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/allowance.dart';
import '../models/expense.dart';
import '../models/savings_entry.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Allowance? allowance;
  double totalSpent = 0;
  bool isLoading = true;
  List<Expense> recentExpenses = [];
  List<String> budgetingTips = [];
  List<SavingsEntry> savingsEntries = [];
  double totalSavedAmount = 0;
  double monthlySavedAmount = 0;
  double monthlySavingsGoal = 0;
  int underBudgetStreak = 0;
  bool showSavingsPrompt = false;
  double savingsPromptAmount = 0;
  DateTime savingsPromptDate = DateTime.now();
  bool showSavingsReminder = false;
  double savingsReminderAmount = 0;
  DateTime savingsReminderDate = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedAllowance = await StorageService.getallowance();
    final spent = await StorageService.getTodayTotalSpent();
    final recent = await StorageService.getRecentExpenses(limit: 5);
    final tips = _generateBudgetingTips(recent, loadedAllowance, spent);
    final savingsList = await StorageService.getSavingsEntries();
    final totalSaved = await StorageService.getTotalSavedAmount();
    final allExpenses = await StorageService.getAllExpenses();
    final today = _normalizeDate(DateTime.now());
    final yesterday = _normalizeDate(DateTime.now().subtract(const Duration(days: 1)));
    final hasLoggedToday = await StorageService.hasSavingsEntryForDate(today);
    bool shouldPrompt = false;
    double leftoverToday = 0;
    bool shouldRemind = false;
    double leftoverYesterday = 0;
    final monthlySaved = _calculateMonthlySaved(savingsList, today);
    final customMonthlyTarget = await StorageService.getSavingsTargetForMonth(today);
    final monthlyGoal = customMonthlyTarget ?? 0;
    final streak = _calculateUnderBudgetStreak(allExpenses, loadedAllowance);

    if (loadedAllowance != null) {
      leftoverToday = loadedAllowance.amount - spent;
      if (leftoverToday < 0) leftoverToday = 0;
      shouldPrompt = leftoverToday > 0 && !hasLoggedToday;

      leftoverYesterday = await _calculateRemainingForDate(yesterday, loadedAllowance);
      final hasLoggedYesterday = await StorageService.hasSavingsEntryForDate(yesterday);
      shouldRemind = leftoverYesterday > 0 && !hasLoggedYesterday;

      if (shouldRemind) {
        final lastReminder = await StorageService.getLastSavingsReminderDate();
        if (lastReminder == null || !_isSameDay(lastReminder, today)) {
          await StorageService.setLastSavingsReminderDate(today);
        }
      }
    }

    setState(() {
      allowance = loadedAllowance;
      totalSpent = spent;
      recentExpenses = recent;
      budgetingTips = tips;
      savingsEntries = savingsList;
      totalSavedAmount = totalSaved;
      monthlySavedAmount = monthlySaved;
      monthlySavingsGoal = monthlyGoal;
      underBudgetStreak = streak;
      showSavingsPrompt = shouldPrompt;
      savingsPromptAmount = leftoverToday;
      savingsPromptDate = today;
      showSavingsReminder = shouldRemind;
      savingsReminderAmount = leftoverYesterday;
      savingsReminderDate = yesterday;
      isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Color _getStatusColor() {
    if (allowance == null || allowance!.amount == 0) return Colors.grey;

    final remaining = allowance!.amount - totalSpent;
    final percentageRemaining = (remaining / allowance!.amount) * 100;
    
    if (percentageRemaining >= 20) {
      return Colors.green;
    } else if (percentageRemaining >= 0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText() {
    if (allowance == null || allowance!.amount == 0) return 'Not Set';
    
    final remaining = allowance!.amount - totalSpent;
    final percentageRemaining = (remaining / allowance!.amount) * 100;
    
    if (percentageRemaining >= 20) {
      return 'Safe';
    } else if (percentageRemaining >= 0) {
      return 'Caution';
    } else {
      return 'Overspending';
    }
  }

  bool get _shouldShowCautionBanner {
    if (allowance == null || allowance!.amount == 0) return false;
    return totalSpent / allowance!.amount >= 0.8;
  }

  List<String> _generateBudgetingTips(
    List<Expense> expenses,
    Allowance? currentAllowance,
    double spent,
  ) {
    final tips = <String>[];
    if (expenses.isEmpty) {
      tips.add('Log expenses today to keep your budget on track.');
      return tips;
    }

    final Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories.take(2)) {
      tips.add('Consider reducing ${entry.key.toLowerCase()} spending (₱${entry.value.toStringAsFixed(2)}).');
    }

    if (currentAllowance != null && currentAllowance.amount > 0) {
      final remaining = currentAllowance.amount - spent;
      if (remaining < 0) {
        tips.add('You have exceeded your allowance by ₱${(remaining.abs()).toStringAsFixed(2)}. Review entries.');
      } else if (spent / currentAllowance.amount >= 0.9) {
        tips.add('Only ₱${remaining.toStringAsFixed(2)} remains. Plan essential expenses first.');
      }
    }

    if (tips.isEmpty) {
      tips.add('Great job staying within budget! Keep monitoring your spending.');
    }

    return tips;
  }

  void _showBudgetTipsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Review Tips',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent Expenses',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...recentExpenses.map(
                (expense) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(expense.name),
                  subtitle: Text(
                    '${expense.category} • ₱${expense.amount.toStringAsFixed(2)}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Suggestions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...budgetingTips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/history');
                  },
                  child: const Text('Go to History'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCautionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caution: You are close to your limit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Review your recent spending before adding new expenses.'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showBudgetTipsModal,
              child: const Text('Review Tips'),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<double> _calculateRemainingForDate(DateTime date, Allowance allowance) async {
    final expenses = await StorageService.getExpensesByDate(date);
    final spent = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final remaining = allowance.amount - spent;
    return remaining > 0 ? remaining : 0;
  }

  void _showSavingsModal(DateTime targetDate, double amount) {
    final normalizedDate = _normalizeDate(targetDate);
    final formattedDate = DateFormat('MMMM d, yyyy').format(normalizedDate);
    final displayAmount = amount < 0 ? 0.0 : amount;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remaining ₱${displayAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('How would you like to handle the leftover from $formattedDate?'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _logSavings(
                    SavingsAction.saved,
                    normalizedDate,
                    displayAmount,
                  );
                },
                icon: const Icon(Icons.savings),
                label: const Text('Move to Savings'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _logSavings(
                    SavingsAction.carryOver,
                    normalizedDate,
                    displayAmount,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Carry Over'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logSavings(
    SavingsAction action,
    DateTime date,
    double amount,
  ) async {
    final entry = SavingsEntry(
      id: '${date.toIso8601String()}_${action.name}',
      amount: amount,
      date: date,
      action: action,
    );

    await StorageService.saveSavingsEntry(entry);
    await _loadData();

    if (!mounted) return;

    final formattedDate = DateFormat('MMM d').format(date);
    final message = action == SavingsAction.saved
        ? 'Saved ₱${amount.toStringAsFixed(2)} from $formattedDate.'
        : 'Marked ₱${amount.toStringAsFixed(2)} to carry over from $formattedDate.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSavingsBanner({
    required bool isReminder,
    required DateTime date,
    required double amount,
  }) {
    final formattedDate = DateFormat('MMMM d').format(date);
    final title = isReminder
        ? 'Log leftover from $formattedDate'
        : 'Log Remaining Allowance';
    final description = isReminder
        ? 'You still have ₱${amount.toStringAsFixed(2)} unlogged from $formattedDate.'
        : 'You have ₱${amount.toStringAsFixed(2)} left today.';
    final buttonLabel = isReminder ? 'Log $formattedDate' : 'Log Now';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _showSavingsModal(date, amount),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsProgressCard() {
    final goal = monthlySavingsGoal;
    final saved = monthlySavedAmount;
    final progress = goal == 0 ? 0.0 : (saved / goal).clamp(0.0, 1.0);
    final monthLabel = DateFormat('MMMM').format(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthLabel Savings Progress',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
            ),
            const SizedBox(height: 8),
            Text(
              goal == 0
                  ? 'Set a monthly target in Savings to track progress.'
                  : '₱${saved.toStringAsFixed(2)} of ₱${goal.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    final hasStreak = underBudgetStreak > 0;
    final title = hasStreak ? 'Great job staying under budget!' : 'Build your first streak';
    final message = hasStreak
        ? 'You have a $underBudgetStreak-day streak of smart spending.'
        : 'Stay under budget today to start your streak.';
    final icon = hasStreak ? Icons.emoji_events : Icons.flag_outlined;
    final color = hasStreak ? Colors.amber : Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMonthlySaved(List<SavingsEntry> entries, DateTime reference) {
    return entries
        .where((entry) =>
            entry.action == SavingsAction.saved &&
            entry.date.year == reference.year &&
            entry.date.month == reference.month)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  int _calculateUnderBudgetStreak(List<Expense> expenses, Allowance? currentAllowance) {
    if (currentAllowance == null || currentAllowance.amount <= 0) return 0;

    final dailyAllowance = currentAllowance.frequency == AllowanceFrequency.daily
        ? currentAllowance.amount
        : currentAllowance.amount / 7;
    if (dailyAllowance <= 0) return 0;

    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        _dateKey(expense.date),
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final today = _normalizeDate(DateTime.now());
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final spent = totals[_dateKey(date)] ?? 0;
      if (spent <= dailyAllowance) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _dateKey(DateTime date) {
    final normalized = _normalizeDate(date);
    return '${normalized.year}-${normalized.month}-${normalized.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (allowance == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/setup');
            },
            child: const Text('Setup Allowance'),
          ),
        ),
      );
    }

    final remaining = allowance!.amount - totalSpent;
    final progressValue = allowance!.amount == 0
      ? 0.0
      : (totalSpent / allowance!.amount).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allowance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings').then((_) {
                _loadData();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Allowance',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${allowance!.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${allowance!.frequency.name.capitalizeFirst()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_shouldShowCautionBanner) _buildCautionBanner(),
                if (showSavingsPrompt)
                  _buildSavingsBanner(
                    isReminder: false,
                    date: savingsPromptDate,
                    amount: savingsPromptAmount,
                  ),
                if (showSavingsReminder)
                  _buildSavingsBanner(
                    isReminder: true,
                    date: savingsReminderDate,
                    amount: savingsReminderAmount,
                  ),
                if (allowance != null) ...[
                  _buildSavingsProgressCard(),
                  const SizedBox(height: 12),
                  _buildStreakCard(),
                  const SizedBox(height: 12),
                ],
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today\'s Spending',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₱${totalSpent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Spent',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₱${remaining.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(),
                                  ),
                                ),
                                const Text(
                                  'Remaining',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 12,
                            value: progressValue,
                            backgroundColor: Colors.grey[300],
                            valueColor:
                              AlwaysStoppedAnimation<Color>(_getStatusColor()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-expense').then((_) {
                      _loadData();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/savings');
                  },
                  icon: const Icon(Icons.savings),
                  label: const Text('View Savings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/category-breakdown');
                  },
                  icon: const Icon(Icons.pie_chart),
                  label: const Text('Category Breakdown'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings').then((_) {
                      _loadData();
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Allowance'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
