import 'package:hive/hive.dart';

part 'recurring_expense.g.dart';

@HiveType(typeId: 2)
class RecurringExpense {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final int frequency; // 1: Daily, 7: Weekly, 30: Monthly

  @HiveField(5)
  final DateTime startDate;

  @HiveField(6)
  final DateTime? endDate;

  @HiveField(7)
  final bool isActive;

  RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory RecurringExpense.fromMap(Map<String, dynamic> map) {
    return RecurringExpense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      frequency: map['frequency'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      isActive: map['isActive'],
    );
  }

  String get frequencyText {
    switch (frequency) {
      case 1:
        return 'Daily';
      case 7:
        return 'Weekly';
      case 30:
        return 'Monthly';
      default:
        return 'Custom';
    }
  }

  DateTime get nextDueDate {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return startDate;

    final difference = now.difference(startDate).inDays;
    final periods = (difference / frequency).ceil();
    return startDate.add(Duration(days: periods * frequency));
  }
} 