import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String? accountId;
  final String type; // 'income', 'expense'
  final String? budgetId;
  final String? description;
  final String? iconPath;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    this.accountId,
    required this.type,
    this.budgetId,
    this.description,
    this.iconPath,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    currency,
    date,
    category,
    accountId,
    type,
    budgetId,
    description,
    iconPath,
  ];
}
