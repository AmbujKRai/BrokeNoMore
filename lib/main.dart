import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('expenseBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrokeNoMore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'BrokeNoMore'), // ← correct placement
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _expenseBox = Hive.box('expenseBox');
  final List<Map<String, dynamic>> _expenses = [];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  String _selectedCategory = 'Food';
  double _budget = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadBudget();
  }

  void _loadExpenses() {
    final savedExpenses = _expenseBox.get('expenses', defaultValue: []);
    setState(() => _expenses.addAll(List<Map<String, dynamic>>.from(savedExpenses)));
  }

  void _saveExpenses() => _expenseBox.put('expenses', _expenses);

  void _loadBudget() {
    final savedBudget = _expenseBox.get('budget', defaultValue: 0.0);
    setState(() => _budget = savedBudget);
  }

  void _saveBudget() => _expenseBox.put('budget', _budget);

  @override
  void dispose() {
    _amountController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _addExpense() {
    if (_amountController.text.isEmpty) return;

    setState(() {
      _expenses.add({
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
        'date': DateTime.now().toString().split(' ')[0],
      });
      _saveExpenses();
      _amountController.clear();
    });
  }

  double _calculateBudgetProgress() {
    if (_budget <= 0) return 0;
    double totalSpent = _expenses.fold(0, (sum, e) => sum + e['amount']);
    return (totalSpent / _budget).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Budget Input
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monthly Budget (₹${_budget.toStringAsFixed(0)})',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    if (_budgetController.text.isNotEmpty) {
                      setState(() {
                        _budget = double.parse(_budgetController.text);
                        _saveBudget();
                        _budgetController.clear();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Budget Progress
            LinearProgressIndicator(
              value: _calculateBudgetProgress(),
              minHeight: 15,
              backgroundColor: Colors.grey[300],
              color: _calculateBudgetProgress() > 0.8 ? Colors.red : Colors.green,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '₹${_expenses.fold(0.0, (sum, e) => sum + e['amount']).toStringAsFixed(0)}'
                    '/₹${_budget.toStringAsFixed(0)} spent',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),

            // Expense Input Form
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addExpense,
              child: const Text('Add Expense'),
            ),
            const SizedBox(height: 20),

            // Expense List
            Expanded(
              child: ListView.builder(
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final expense = _expenses[index];
                  return ListTile(
                    leading: Icon(_getCategoryIcon(expense['category']),
                        color: Colors.green),
                    title: Text('₹${expense['amount'].toStringAsFixed(0)}'),
                    subtitle: Text(expense['category']),
                    trailing: Text(expense['date']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.money_off;
    }
  }
}