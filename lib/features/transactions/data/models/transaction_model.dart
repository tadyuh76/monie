import 'package:monie/features/transactions/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.date,
    required super.description,
    required super.title,
    required super.userId,
    super.categoryName,
    super.categoryColor,
    super.accountId,
    super.budgetId,
    super.isRecurring,
    super.receiptUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['transaction_id'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
      title: json['title'] ?? '',
      userId: json['user_id'],
      categoryName: json['category_name'],
      categoryColor: json['category_color'],
      accountId: json['account_id'],
      budgetId: json['budget_id'],
      isRecurring: json['is_recurring'] ?? false,
      receiptUrl: json['receipt_url'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'title': title,
      'user_id': userId,
      'category_name': categoryName,
      'category_color': categoryColor,
      'account_id': accountId,
      'budget_id': budgetId,
      'is_recurring': isRecurring ?? false,
      'receipt_url': receiptUrl,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      date: entity.date,
      description: entity.description,
      title: entity.title,
      userId: entity.userId,
      categoryName: entity.categoryName,
      categoryColor: entity.categoryColor,
      accountId: entity.accountId,
      budgetId: entity.budgetId,
      isRecurring: entity.isRecurring,
      receiptUrl: entity.receiptUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
