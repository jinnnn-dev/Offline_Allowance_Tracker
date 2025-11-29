import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import 'add_expense_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Expense> expenses = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 0: List, 1: Weekly, 2: Monthly
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final loadedExpenses = await StorageService.getAllExpenses();
    loadedExpenses.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() {
      expenses = loadedExpenses;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteExpense(String id) async {
    await StorageService.deleteExpense(id);
    await _loadExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    }
  }

  void _editExpense(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(expense: expense),
      ),
    ).then((_) => _loadExpenses());
  }

  List<Expense> _getFilteredExpenses() {
    var list = expenses;
    if (_selectedFilter != 'All') {
      list = list.where((e) => e.category == _selectedFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        final dateStr = DateFormat('MMMM d, yyyy').format(e.date).toLowerCase();
        return e.name.toLowerCase().contains(q) || e.category.toLowerCase().contains(q) || dateStr.contains(q) || (e.note ?? '').toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  Map<String, List<Expense>> _groupExpensesByDate(List<Expense> expenseList) {
    final grouped = <String, List<Expense>>{};
    for (var expense in expenseList) {
      final dateKey = DateFormat('MMMM d, yyyy').format(expense.date);
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredExpenses = _getFilteredExpenses();
    final groupedExpenses = _groupExpensesByDate(filteredExpenses);
    final weeklySummary = _groupExpensesByWeek(filteredExpenses);
    final monthlySummary = _groupExpensesByMonth(filteredExpenses);

    return Scaffold(
      appBar: AppBar(title: const Text('Expense History')),
      body: filteredExpenses.isEmpty && _viewMode == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No expenses yet'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-expense')
                          .then((_) => _loadExpenses());
                    },
                    child: const Text('Add Expense'),
                  ),
                ],
              ),
            )
            : RefreshIndicator(
                onRefresh: _loadExpenses,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search by name, category, note or date',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                          ),
                          const SizedBox(height: 8),
                          ToggleButtons(
                            isSelected: [_viewMode == 0, _viewMode == 1, _viewMode == 2],
                            onPressed: (index) => setState(() => _viewMode = index),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('List'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('Weekly'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('Monthly'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            ...categories.map((cat) => _buildFilterChip(cat)),
                          ],
                        ),
                      ),
                    ),
                    if (_viewMode == 0) ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: groupedExpenses.entries.length,
                        itemBuilder: (context, index) {
                          final entry = groupedExpenses.entries.elementAt(index);
                          final dateKey = entry.key;
                          final dateExpenses = entry.value;
                          final dayTotal = dateExpenses.fold<double>(0, (sum, e) => sum + e.amount);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateKey,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '₱${dayTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                              ...dateExpenses.map((expense) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.withOpacity(0.2),
                                    child: Icon(_getCategoryIcon(expense.category), color: Colors.blue),
                                  ),
                                  title: Text(expense.name),
                                  subtitle: Text(expense.category),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text('Edit'),
                                        onTap: () => _editExpense(expense),
                                      ),
                                      PopupMenuItem(
                                        child: const Text('Delete'),
                                        onTap: () => _deleteExpense(expense.id),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _editExpense(expense),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ] else if (_viewMode == 1) ...[
                      // Weekly summary
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: weeklySummary.entries.map((entry) {
                            final weekLabel = entry.key;
                            final total = entry.value;
                            return ListTile(
                              title: Text(weekLabel),
                              trailing: Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...[
                      // Monthly summary
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: monthlySummary.entries.map((entry) {
                            final monthLabel = entry.key;
                            final total = entry.value;
                            return ListTile(
                              title: Text(monthLabel),
                              trailing: Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Map<String, double> _groupExpensesByWeek(List<Expense> expenseList) {
    final map = <String, double>{};
    for (final e in expenseList) {
      // week label: "MMM d - MMM d" (Monday - Sunday)
      final monday = e.date.subtract(Duration(days: e.date.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final label = '${DateFormat('MMM d').format(monday)} - ${DateFormat('MMM d').format(sunday)}';
      map.update(label, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    // sort by newest week first using the monday date
    final entries = map.entries.toList();
    entries.sort((a, b) {
      final aDate = DateFormat('MMM d').parse(a.key.split(' - ').first);
      final bDate = DateFormat('MMM d').parse(b.key.split(' - ').first);
      return bDate.compareTo(aDate);
    });
    return Map.fromEntries(entries);
  }

  Map<String, double> _groupExpensesByMonth(List<Expense> expenseList) {
    final map = <String, double>{};
    for (final e in expenseList) {
      final label = DateFormat('MMMM yyyy').format(e.date);
      map.update(label, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final entries = map.entries.toList();
    entries.sort((a, b) {
      final aDate = DateFormat('MMMM yyyy').parse(a.key);
      final bDate = DateFormat('MMMM yyyy').parse(b.key);
      return bDate.compareTo(aDate);
    });
    return Map.fromEntries(entries);
  }

  Widget _buildFilterChip(String category) {
    final isSelected = _selectedFilter == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = category);
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'School':
        return Icons.school;
      case 'Transportation':
        return Icons.directions_bus;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.shopping_bag;
    }
  }
}
