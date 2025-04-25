import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ExpenseAnalysis extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;

  const ExpenseAnalysis({super.key, required this.expenses});

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> categoryTotals = {};
    
    for (var expense in expenses) {
      final category = expense['category'] as String;
      final amount = expense['amount'] as double;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }
    
    return categoryTotals;
  }

  List<PieChartSectionData> _createPieChartSections(Map<String, double> categoryTotals) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    int colorIndex = 0;

    return categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _calculateCategoryTotals();
    final totalExpense = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Expense Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Pie Chart
              if (categoryTotals.isNotEmpty)
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sections: _createPieChartSections(categoryTotals),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                )
              else
                const Center(
                  child: Text('No expenses to analyze'),
                ),
              const SizedBox(height: 24),
              // Category Breakdown
              const Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...categoryTotals.entries.map((entry) {
                final percentage = (entry.value / totalExpense) * 100;
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    subtitle: LinearProgressIndicator(
                      value: entry.value / totalExpense,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    trailing: Text(
                      '₹${entry.value.toStringAsFixed(2)}\n(${percentage.toStringAsFixed(1)}%)',
                      textAlign: TextAlign.end,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
} 