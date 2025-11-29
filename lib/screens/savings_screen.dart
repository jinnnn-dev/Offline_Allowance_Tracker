import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings_entry.dart';
import '../services/storage_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({Key? key}) : super(key: key);

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<SavingsEntry> entries = [];
  double totalSaved = 0;
  bool isLoading = true;
  Map<String, double> monthlyTargets = {};

  @override
  void initState() {
    super.initState();
    _loadSavings();
  }

  Future<void> _loadSavings() async {
    final loadedEntries = await StorageService.getSavingsEntries();
    loadedEntries.sort((a, b) => b.date.compareTo(a.date));
    final savedTotal = loadedEntries
        .where((entry) => entry.isSaved)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final targets = await StorageService.getAllSavingsTargets();

    setState(() {
      entries = loadedEntries;
      totalSaved = savedTotal;
      monthlyTargets = targets;
      isLoading = false;
    });
  }

  Future<void> _refreshTargets() async {
    final targets = await StorageService.getAllSavingsTargets();
    if (!mounted) return;
    setState(() {
      monthlyTargets = targets;
    });
  }

  Future<void> _showTargetDialog() async {
    DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add Monthly Target'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedMonth,
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 5),
                        helpText: 'Select Month',
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedMonth = DateTime(picked.year, picked.month);
                        });
                      }
                    },
                    child: Text(DateFormat('MMMM yyyy').format(selectedMonth)),
                  ),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Target Amount'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text);
                    if (amount == null || amount <= 0) return;
                    await StorageService.saveSavingsTarget(selectedMonth, amount);
                    await _refreshTargets();
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTarget(String key) async {
    final date = _monthFromKey(key);
    await StorageService.deleteSavingsTarget(date);
    await _refreshTargets();
  }

  DateTime _monthFromKey(String key) {
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTime(year, month);
  }

  String _formatMonthLabel(String key) {
    return DateFormat('MMMM yyyy').format(_monthFromKey(key));
  }

  Widget _buildTargetsCard() {
    final targets = monthlyTargets.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Targets',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showTargetDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Target'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (targets.isEmpty)
              const Text('No monthly targets yet.')
            else
              Column(
                children: [
                  for (var i = 0; i < targets.length; i++) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_formatMonthLabel(targets[i].key)),
                      subtitle: Text('₱${targets[i].value.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTarget(targets[i].key),
                      ),
                    ),
                    if (i != targets.length - 1) const Divider(),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Overview')),
      body: RefreshIndicator(
        onRefresh: _loadSavings,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Saved',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${totalSaved.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTargetsCard(),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No savings logged yet.'),
                ),
              )
            else
              ...entries.map((entry) => _buildEntryTile(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(SavingsEntry entry) {
    final dateText = DateFormat('MMMM d, yyyy').format(entry.date);
    final actionText = entry.action == SavingsAction.saved
        ? 'Moved to savings'
        : 'Carried over';
    final actionColor = entry.action == SavingsAction.saved
        ? Colors.green
        : Colors.orange;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: actionColor.withOpacity(0.15),
          child: Icon(
            entry.action == SavingsAction.saved
                ? Icons.savings
                : Icons.refresh,
            color: actionColor,
          ),
        ),
        title: Text('₱${entry.amount.toStringAsFixed(2)}'),
        subtitle: Text('$actionText • $dateText'),
      ),
    );
  }
}
