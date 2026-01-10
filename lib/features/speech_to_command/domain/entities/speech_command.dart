import 'package:equatable/equatable.dart';

/// Entity representing a parsed speech command for creating a transaction
class SpeechCommand extends Equatable {
  final double amount;
  final String? categoryName;
  final String? title;
  final String? description;
  final bool isIncome;
  final String? accountId;
  final DateTime? date;
  final double confidence;

  const SpeechCommand({
    required this.amount,
    this.categoryName,
    this.title,
    this.description,
    this.isIncome = false,
    this.accountId,
    this.date,
    this.confidence = 1.0,
  });

  @override
  List<Object?> get props => [
        amount,
        categoryName,
        title,
        description,
        isIncome,
        accountId,
        date,
        confidence,
      ];

  /// Check if command is valid (has amount)
  bool get isValid => amount > 0;

  /// Convert to transaction data map for form pre-filling
  Map<String, dynamic> toTransactionData() {
    return {
      'title': title ?? description ?? (isIncome ? 'Income' : 'Expense'),
      'description': description,
      'amount': isIncome ? amount : -amount,
      'date': date ?? DateTime.now(),
      'category_name': categoryName,
      'is_income': isIncome,
    };
  }
}

