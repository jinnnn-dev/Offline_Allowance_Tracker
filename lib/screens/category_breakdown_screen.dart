import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';

class CategoryBreakdownScreen extends StatefulWidget {
  const CategoryBreakdownScreen({Key? key}) : super(key: key);

  @override
  State<CategoryBreakdownScreen> createState() => _CategoryBreakdownScreenState();
}

class _CategoryBreakdownScreenState extends State<CategoryBreakdownScreen> {
  bool isLoading = true;
  Map<String, double> categoryTotals = {};
  double grandTotal = 0;
  int _selectedTimePeriod = 0; // 0: This Month, 1: This Week, 2: All Time

  // Color palette for categories
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF6B6B),
    'School': Color(0xFF4ECDC4),
    'Transportation': Color(0xFFFFE66D),
    'Entertainment': Color(0xFF95E1D3),
    'Other': Color(0xFFC7CEEA),
  };

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    final expenses = await StorageService.getAllExpenses();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    List<Expense> filteredExpenses;

    if (_selectedTimePeriod == 0) {
      // This Month
      filteredExpenses =
          expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else if (_selectedTimePeriod == 1) {
      // This Week
      filteredExpenses = expenses.where((e) {
        final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
        return expenseDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            expenseDate.isBefore(today.add(const Duration(days: 1)));
      }).toList();
    } else {
      // All Time
      filteredExpenses = expenses;
    }

    final totals = <String, double>{};
    double total = 0;

    for (final expense in filteredExpenses) {
      totals.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
      total += expense.amount;
    }

    setState(() {
      categoryTotals = totals;
      grandTotal = total;
      isLoading = false;
    });
  }

  List<PieChartSectionData> _buildPieChartSections() {
    if (categoryTotals.isEmpty) {
      return [];
    }

    return categoryTotals.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = (amount / grandTotal) * 100;
      final color = categoryColors[category] ?? const Color(0xFFC7CEEA);

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Category Breakdown')),
      body: categoryTotals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No spending data yet'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-expense').then((_) {
                        _loadCategoryData();
                      });
                    },
                    child: const Text('Add Expense'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCategoryData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Time Period Selector
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(label: Text('This Month'), value: 0),
                        ButtonSegment(label: Text('This Week'), value: 1),
                        ButtonSegment(label: Text('All Time'), value: 2),
                      ],
                      selected: {_selectedTimePeriod},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _selectedTimePeriod = newSelection.first;
                          isLoading = true;
                        });
                        _loadCategoryData();
                      },
                    ),
                  ),

                  // Pie Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spending by Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: PieChart(
                              PieChartData(
                                sections: _buildPieChartSections(),
                                centerSpaceRadius: 40,
                                sectionsSpace: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Category Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...categoryTotals.entries.map((entry) {
                            final category = entry.key;
                            final amount = entry.value;
                            final percentage = (amount / grandTotal) * 100;
                            final color = categoryColors[category] ?? const Color(0xFFC7CEEA);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}% • ₱${amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₱${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Spending',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₱${grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Top Spending Category Alert
                  if (categoryTotals.isNotEmpty) ...[
                    Card(
                      color: Colors.orange.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Top Spending Category',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key} (${((categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).value / grandTotal) * 100).toStringAsFixed(1)}%)',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
