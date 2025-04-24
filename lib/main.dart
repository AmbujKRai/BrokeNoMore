import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final expenseBox = await Hive.openBox('expenseBox');
  await expenseBox.clear(); // Clear any corrupted data
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
  List<Map<String, dynamic>> _expenses = [];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  String _selectedCategory = 'Hostel mess';
  double _budget = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadBudget();
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
                value: 'Hostel mess',
                child: Text('Hostel mess'),
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
                  value: 'Toiletries',
                  child: Text('Toiletries'),
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
                  'date': _expenses[index]['date'], // Keep original date
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
    if (!['Hostel mess', 'Transport', 'Movies', 'Party', 'Toiletries','Bills']
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
    return (totalSpent / _budget).clamp(0, 1);
  }

  // Helper method to prepare chart data
  List<BarChartGroupData> _prepareChartData() {
    // Group expenses by date
    final Map<String, double> expensesByDate = {};
    for (var expense in _expenses) {
      final date = expense['date'] as String;
      expensesByDate[date] = (expensesByDate[date] ?? 0) + (expense['amount'] as double);
    }

    // Convert to list and sort by date
    final sortedDates = expensesByDate.keys.toList()..sort();

    // Return bar chart data
    return List.generate(
      sortedDates.length,
          (index) {
        final date = sortedDates[index];
        final amount = expensesByDate[date] ?? 0;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Colors.green,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      },
    );
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
                '₹${_expenses.fold(0.0, (sum, e) => sum + (e['amount'] as double)).toStringAsFixed(0)}'
                    '/₹${_budget.toStringAsFixed(0)} spent',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),

            // New Chart using fl_chart
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _expenses.isEmpty
                  ? const Center(child: Text('No expenses to display'))
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _expenses.isEmpty
                      ? 100
                      : _expenses
                      .map((e) => e['amount'] as double)
                      .reduce((a, b) => a > b ? a : b) * 1.2,
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < _prepareChartData().length) {
                            // Show abbreviated date (e.g., "4/24")
                            final date = _expenses[value.toInt()]['date'] as String;
                            final parts = date.split('-');
                            if (parts.length >= 3) {
                              return Text('${parts[1]}/${parts[2]}');
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _prepareChartData(),
                ),
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
                DropdownMenuItem(value: 'Hostel mess', child: Text('Hostel mess')),
                DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                DropdownMenuItem(value: 'Movies', child: Text('Movies')),
                DropdownMenuItem(value: 'Party', child: Text('Party')),
                DropdownMenuItem(value: 'Toiletries', child: Text('Toiletries')),
                DropdownMenuItem(value: 'Bills', child: Text('Bills')),
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
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hostel mess':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Movies':
        return Icons.movie;
      case 'Party':
        return Icons.celebration;
      case 'Toiletries':
        return Icons.soap;
      case 'Bills':
        return Icons.description;
      default:
        return Icons.money_off;
    }
  }
}