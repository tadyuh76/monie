import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String title;
  final String userId;
  final String? categoryName;
  final String? categoryColor;
  final String? accountId;
  final String? budgetId;
  final bool? isRecurring;
  final String? receiptUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.title,
    required this.userId,
    this.categoryName,
    this.categoryColor,
    this.accountId,
    this.budgetId,
    this.isRecurring,
    this.receiptUrl,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    date,
    description,
    title,
    userId,
    categoryName,
    categoryColor,
    accountId,
    budgetId,
    isRecurring,
    receiptUrl,
    createdAt,
    updatedAt,
  ];
}
