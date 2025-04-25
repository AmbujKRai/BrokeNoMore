import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_expense.dart';
import 'package:uuid/uuid.dart';

class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  final _recurringBox = Hive.box('recurringExpenses');
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Bills';
  int _selectedFrequency = 30; // Default to monthly
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addRecurringExpense() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid details')),
      );
      return;
    }

    final expense = RecurringExpense(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      category: _selectedCategory,
      frequency: _selectedFrequency,
      startDate: _startDate,
    );

    final expenses = List<Map<String, dynamic>>.from(
      _recurringBox.get('expenses', defaultValue: []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    expenses.add(expense.toMap());
    _recurringBox.put('expenses', expenses);

    _titleController.clear();
    _amountController.clear();
    setState(() {});
  }

  void _deleteRecurringExpense(int index) {
    final expenses = List<Map<String, dynamic>>.from(
      _recurringBox.get('expenses', defaultValue: []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    expenses.removeAt(index);
    _recurringBox.put('expenses', expenses);
    setState(() {});
  }

  void _toggleExpenseStatus(int index) {
    final expenses = List<Map<String, dynamic>>.from(
      _recurringBox.get('expenses', defaultValue: []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final expense = RecurringExpense.fromMap(expenses[index]);
    expenses[index] = RecurringExpense(
      id: expense.id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      frequency: expense.frequency,
      startDate: expense.startDate,
      endDate: expense.endDate,
      isActive: !expense.isActive,
    ).toMap();
    _recurringBox.put('expenses', expenses);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final expenses = List<Map<String, dynamic>>.from(
      _recurringBox.get('expenses', defaultValue: []).map((e) => Map<String, dynamic>.from(e as Map)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Expenses'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                    DropdownMenuItem(value: 'Subscription', child: Text('Subscription')),
                    DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Daily')),
                    DropdownMenuItem(value: 7, child: Text('Weekly')),
                    DropdownMenuItem(value: 30, child: Text('Monthly')),
                  ],
                  onChanged: (value) => setState(() => _selectedFrequency = value!),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(_startDate.toString().split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addRecurringExpense,
                  child: const Text('Add Recurring Expense'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = RecurringExpense.fromMap(expenses[index]);
                return Dismissible(
                  key: Key(expense.id),
                  onDismissed: (_) => _deleteRecurringExpense(index),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Icon(
                      expense.isActive ? Icons.check_circle : Icons.cancel,
                      color: expense.isActive ? Colors.green : Colors.red,
                    ),
                    title: Text(expense.title),
                    subtitle: Text(
                      '${expense.frequencyText} - ₹${expense.amount.toStringAsFixed(2)}\n'
                      'Next due: ${expense.nextDueDate.toString().split(' ')[0]}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _toggleExpenseStatus(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 