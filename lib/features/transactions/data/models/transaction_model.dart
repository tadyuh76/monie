import 'package:monie/features/transactions/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.currency,
    required super.date,
    required super.category,
    super.accountId,
    required super.type,
    super.budgetId,
    super.description,
    super.iconPath,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      accountId: json['accountId'],
      type: json['type'],
      budgetId: json['budgetId'],
      description: json['description'],
      iconPath: json['iconPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'category': category,
      'accountId': accountId,
      'type': type,
      'budgetId': budgetId,
      'description': description,
      'iconPath': iconPath,
    };
  }

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      currency: entity.currency,
      date: entity.date,
      category: entity.category,
      accountId: entity.accountId,
      type: entity.type,
      budgetId: entity.budgetId,
      description: entity.description,
      iconPath: entity.iconPath,
    );
  }
}
