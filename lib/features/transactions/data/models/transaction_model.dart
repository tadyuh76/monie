import 'package:monie/features/transactions/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  TransactionModel({
    super.transactionId,
    super.accountId,
    super.budgetId,
    required super.userId,
    required super.title,
    required super.amount,
    super.date,
    super.description,
    super.categoryName,
    super.color,
    super.isRecurring,
    super.receiptUrl,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transaction_id'],
      accountId: json['account_id'],
      budgetId: json['budget_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      title: json['title'],
      description: json['description'],
      categoryName: json['category_name'],
      color: json['color'],
      isRecurring: json['is_recurring'] ?? false,
      receiptUrl: json['receipt_url'],
    );
  }

  Map<String, dynamic> toJson() {
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

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      transactionId: entity.transactionId,
      accountId: entity.accountId,
      budgetId: entity.budgetId,
      userId: entity.userId,
      amount: entity.amount,
      date: entity.date,
      title: entity.title,
      description: entity.description,
      categoryName: entity.categoryName,
      color: entity.color,
      isRecurring: entity.isRecurring,
      receiptUrl: entity.receiptUrl,
    );
  }
}
