import 'package:flutter/material.dart';
import '../models/allowance.dart';
import '../services/storage_service.dart';

class AllowanceSetupScreen extends StatefulWidget {
  final bool isFirstTime;

  const AllowanceSetupScreen({Key? key, this.isFirstTime = true})
      : super(key: key);

  @override
  State<AllowanceSetupScreen> createState() => _AllowanceSetupScreenState();
}

class _AllowanceSetupScreenState extends State<AllowanceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  AllowanceFrequency _selectedFrequency = AllowanceFrequency.daily;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    if (!widget.isFirstTime) {
      _loadCurrentAllowance();
    }
  }

  Future<void> _loadCurrentAllowance() async {
    final allowance = await StorageService.getallowance();
    if (allowance != null) {
      _amountController.text = allowance.amount.toString();
      _selectedFrequency = allowance.frequency;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveAllowance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final allowance = Allowance(
        amount: double.parse(_amountController.text),
        frequency: _selectedFrequency,
        lastResetDate: DateTime.now(),
      );

      await StorageService.saveAllowance(allowance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allowance saved successfully!')),
        );
        
        if (widget.isFirstTime) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving allowance: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Allowance'),
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isFirstTime) ...[
                const Icon(
                  Icons.savings,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set up your daily or weekly allowance to get started',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Allowance Amount (₱)',
                        hintText: '150.00',
                        prefixIcon: Icon(Icons.payments),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Frequency',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          RadioListTile<AllowanceFrequency>(
                            title: const Text('Daily'),
                            subtitle: const Text('Allowance resets every day'),
                            value: AllowanceFrequency.daily,
                            groupValue: _selectedFrequency,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFrequency = value);
                              }
                            },
                          ),
                          RadioListTile<AllowanceFrequency>(
                            title: const Text('Weekly'),
                            subtitle: const Text('Allowance resets every week'),
                            value: AllowanceFrequency.weekly,
                            groupValue: _selectedFrequency,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFrequency = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveAllowance,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Allowance'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
