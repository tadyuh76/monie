import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Transaction extends Equatable {
  final String transactionId;
  final String? accountId;
  final String? budgetId;
  final String userId;
  final double amount;
  final DateTime date;
  final String title;
  final String? description;
  final String? categoryName;
  final String? color;
  final bool isRecurring;
  final String? receiptUrl;

  Transaction({
    String? transactionId,
    this.accountId,
    this.budgetId,
    required this.userId,
    required this.amount,
    DateTime? date,
    required this.title,
    this.description,
    this.categoryName,
    this.color,
    this.isRecurring = false,
    this.receiptUrl,
  }) : transactionId = transactionId ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  @override
  List<Object?> get props => [
    transactionId,
    accountId,
    budgetId,
    userId,
    amount,
    date,
    title,
    description,
    categoryName,
    color,
    isRecurring,
    receiptUrl,
  ];

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      transactionId: map['transaction_id'],
      accountId: map['account_id'],
      budgetId: map['budget_id'],
      userId: map['user_id'],
      amount: map['amount'] is int ? map['amount'].toDouble() : map['amount'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      title: map['title'],
      description: map['description'],
      categoryName: map['category_name'],
      color: map['color'],
      isRecurring: map['is_recurring'] ?? false,
      receiptUrl: map['receipt_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'account_id': accountId,
      'budget_id': budgetId,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'category_name': categoryName,
      'color': color,
      'is_recurring': isRecurring,
      'receipt_url': receiptUrl,
    };
  }

  Transaction copyWith({
    String? transactionId,
    String? accountId,
    String? budgetId,
    String? userId,
    double? amount,
    DateTime? date,
    String? title,
    String? description,
    String? categoryName,
    String? color,
    bool? isRecurring,
    String? receiptUrl,
  }) {
    return Transaction(
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      budgetId: budgetId ?? this.budgetId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryName: categoryName ?? this.categoryName,
      color: color ?? this.color,
      isRecurring: isRecurring ?? this.isRecurring,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}
