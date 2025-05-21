import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String budgetId;
  final String userId;
  final String name;
  final double amount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isRecurring;
  final bool isSaving;
  final String? frequency;
  final String? color;

  const Budget({
    required this.budgetId,
    required this.userId,
    required this.name,
    required this.amount,
    required this.startDate,
    this.endDate,
    this.isRecurring = false,
    this.isSaving = false,
    this.frequency,
    this.color,
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
    );
  }
}
