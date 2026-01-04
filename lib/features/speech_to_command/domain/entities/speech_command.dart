import 'package:equatable/equatable.dart';

/// Entity representing a parsed speech command for creating a transaction
class SpeechCommand extends Equatable {
  final double amount;
  final String? categoryName;
  final String? description;
  final bool isIncome;
  final String? accountId;

  const SpeechCommand({
    required this.amount,
    this.categoryName,
    this.description,
    this.isIncome = false,
    this.accountId,
  });

  @override
  List<Object?> get props => [
        amount,
        categoryName,
        description,
        isIncome,
        accountId,
      ];

  /// Check if command is valid (has amount)
  bool get isValid => amount > 0;
}

