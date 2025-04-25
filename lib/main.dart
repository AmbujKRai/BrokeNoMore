import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'receipt_scanner.dart';
import 'theme_provider.dart';
import 'expense_analysis.dart';
import 'screens/recurring_expenses_screen.dart';
import 'models/recurring_expense.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final expenseBox = await Hive.openBox('expenseBox');
  final recurringBox = await Hive.openBox('recurringExpenses');
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrokeNoMore',
      debugShowCheckedModeBanner: false,
      theme: context.watch<ThemeProvider>().themeData,
      home: const MyHomePage(title: 'BrokeNoMore'),
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
  final _recurringBox = Hive.box('recurringExpenses');
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _recurringExpenses = [];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  String _selectedCategory = 'Food';
  double _budget = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadBudget();
    _loadRecurringExpenses();
  }

  void _loadExpenses() {
    final savedExpenses = _expenseBox.get('expenses', defaultValue: []);
    setState(() {
      _expenses = List<Map<String, dynamic>>.from(
          savedExpenses.map((e) => Map<String, dynamic>.from(e))
      );
    });
  }

  void _saveExpenses() => _expenseBox.put('expenses', _expenses);

  void _loadBudget() {
    final savedBudget = _expenseBox.get('budget', defaultValue: 0.0);
    setState(() => _budget = savedBudget);
  }

  void _saveBudget() => _expenseBox.put('budget', _budget);

  void _loadRecurringExpenses() {
    final savedRecurringExpenses = _recurringBox.get('expenses', defaultValue: []);
    setState(() {
      _recurringExpenses = List<Map<String, dynamic>>.from(
        savedRecurringExpenses.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    });
  }

  List<RecurringExpense> _getUpcomingRecurringExpenses() {
    final now = DateTime.now();
    return _recurringExpenses
        .map((e) => RecurringExpense.fromMap(e))
        .where((e) => e.isActive && e.nextDueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
      _saveExpenses();
    });
  }

  void _editExpense(int index) {
    _amountController.text = _expenses[index]['amount'].toString();
    _selectedCategory = _expenses[index]['category'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: const [DropdownMenuItem(
                value: 'Food',
                child: Text('Food'),
              ),
                DropdownMenuItem(
                  value: 'Transport',
                  child: Text('Transport'),
                ),
                DropdownMenuItem(
                  value: 'Movies',
                  child: Text('Movies'),
                ),
                DropdownMenuItem(
                  value: 'Party',
                  child: Text('Party'),
                ),
                DropdownMenuItem(
                  value: 'Stationery',
                  child: Text('Stationery'),
                ),
                DropdownMenuItem(
                  value: 'Bills',
                  child: Text('Bills'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _expenses[index] = {
                  'amount': double.parse(_amountController.text),
                  'category': _selectedCategory,
                  'date': _expenses[index]['date'],
                };
                _saveExpenses();
                _amountController.clear();
                Navigator.pop(context);
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (!['Food', 'Transport', 'Movies', 'Party', 'Stationery','Bills']
        .contains(_selectedCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid category selected')));
      return;
    }

    setState(() {
      _expenses.add(Map<String, dynamic>.from({
        'amount': amount,
        'category': _selectedCategory,
        'date': DateTime.now().toString().split(' ')[0],
      }));
      _saveExpenses();
      _amountController.clear();
    });
  }

  double _calculateBudgetProgress() {
    if (_budget <= 0) return 0;
    double totalSpent = _expenses.fold(0, (sum, e) => sum + (e['amount'] as double));
    return totalSpent / _budget;
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = _expenses.fold(0.0, (sum, e) => sum + (e['amount'] as double));
    final progress = _calculateBudgetProgress();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final upcomingRecurring = _getUpcomingRecurringExpenses();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecurringExpensesScreen(),
                ),
              ).then((_) => setState(() => _loadRecurringExpenses()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseAnalysis(expenses: _expenses),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Budget (₹${_budget.toStringAsFixed(0)})',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      final budget = double.tryParse(_budgetController.text);
                      if (budget != null && budget > 0) {
                        setState(() {
                          _budget = budget;
                          _saveBudget();
                          _budgetController.clear();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 1 ? Colors.red : Colors.green,
                    ),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${totalSpent.toStringAsFixed(0)}/₹${_budget.toStringAsFixed(0)} spent',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: progress > 1 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const Divider(),
              if (upcomingRecurring.isNotEmpty) ...[
                const Text(
                  'Upcoming Recurring Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingRecurring.length,
                  itemBuilder: (context, index) {
                    final expense = upcomingRecurring[index];
                    return ListTile(
                      leading: const Icon(Icons.repeat),
                      title: Text(expense.title),
                      subtitle: Text(
                        'Due: ${expense.nextDueDate.toString().split(' ')[0]}\n'
                        '${expense.frequencyText} - ₹${expense.amount.toStringAsFixed(2)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _expenses.add({
                              'amount': expense.amount,
                              'category': expense.category,
                              'date': DateTime.now().toString().split(' ')[0],
                            });
                            _saveExpenses();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Expense added successfully'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const Divider(),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Food', child: Text('Food')),
                        DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                        DropdownMenuItem(value: 'Movies', child: Text('Movies')),
                        DropdownMenuItem(value: 'Party', child: Text('Party')),
                        DropdownMenuItem(value: 'Stationery', child: Text('Stationery')),
                        DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value!),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addExpense,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptScanner(
                        onExpenseExtracted: (amount, category) {
                          setState(() {
                            _expenses.add({
                              'amount': amount,
                              'category': category,
                              'date': DateTime.now().toString().split(' ')[0],
                            });
                            _saveExpenses();
                          });
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.document_scanner),
                label: const Text('Scan Receipt'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final expense = _expenses[index];
                  return ListTile(
                    leading: Icon(_getCategoryIcon(expense['category'])),
                    title: Text('₹${expense['amount'].toStringAsFixed(0)}'),
                    subtitle: Text(expense['category']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(expense['date']),
                        IconButton(
                          onPressed: () => _deleteExpense(index),
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                    onTap: () => _editExpense(index),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Movies':
        return Icons.movie;
      case 'Party':
        return Icons.celebration;
      case 'Stationery':
        return Icons.menu_book;
      case 'Bills':
        return Icons.description;
      default:
        return Icons.money_off;
    }
  }
}