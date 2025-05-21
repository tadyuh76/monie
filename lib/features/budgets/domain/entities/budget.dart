import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String budgetId;
  final String userId;
  final String name;
  final double amount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isRecurring;
  final bool isSaving; // When true, this is an income budget
  final String? frequency;
  final String? color;
  final double?
  spent; // Calculated field for the amount spent against this budget

  const Budget({
    required this.budgetId,
    required this.userId,
    required this.name,
    required this.amount,
    required this.startDate,
    this.endDate,
    this.isRecurring = false,
    this.isSaving = false, // Default to expense (not saving)
    this.frequency,
    this.color,
    this.spent,
  });

  @override
  List<Object?> get props => [
    budgetId,
    userId,
    name,
    amount,
    startDate,
    endDate,
    isRecurring,
    isSaving,
    frequency,
    color,
    spent,
  ];

  Budget copyWith({
    String? budgetId,
    String? userId,
    String? name,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurring,
    bool? isSaving,
    String? frequency,
    String? color,
    double? spent,
  }) {
    return Budget(
      budgetId: budgetId ?? this.budgetId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRecurring: isRecurring ?? this.isRecurring,
      isSaving: isSaving ?? this.isSaving,
      frequency: frequency ?? this.frequency,
      color: color ?? this.color,
      spent: spent ?? this.spent,
    );
  }

  // Helper method to calculate remaining amount
  double get remainingAmount {
    final spentAmount = spent ?? 0;
    return amount - spentAmount;
  }

  // Helper method to get spent amount
  double get spentAmount => spent ?? 0;

  // Helper to format spent amount for display
  String get formattedSpentAmount => '\$${spentAmount.toStringAsFixed(2)}';

  // Helper to format remaining amount for display
  String get formattedRemainingAmount =>
      '\$${remainingAmount.toStringAsFixed(2)}';

  // Helper to format total amount for display
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  // Convenience getter for legacy code compatibility
  double get remaining => remainingAmount;

  // Helper to calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (amount <= 0) return 0;
    return (spentAmount / amount).clamp(0.0, 1.0);
  }

  // Check if budget is over limit
  bool get isOverLimit => progressPercentage >= 1.0;

  // Convenience method to check if this is an income budget
  bool get isIncome => isSaving;

  // Convenience method to check if this is an expense budget
  bool get isExpense => !isSaving;
}
