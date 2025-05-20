import 'package:monie/features/transactions/domain/entities/budget.dart';

class BudgetModel extends Budget {
  BudgetModel({
    super.budgetId,
    required super.userId,
    required super.name,
    required super.amount,
    required super.startDate,
    super.endDate,
    super.isRecurring,
    super.isSaving,
    super.frequency,
    super.color,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      budgetId: json['budget_id'],
      userId: json['user_id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isRecurring: json['is_recurring'] ?? false,
      isSaving: json['is_saving'] ?? false,
      frequency: json['frequency'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budget_id': budgetId,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_recurring': isRecurring,
      'is_saving': isSaving,
      'frequency': frequency,
      'color': color,
    };
  }

  factory BudgetModel.fromEntity(Budget entity) {
    return BudgetModel(
      budgetId: entity.budgetId,
      userId: entity.userId,
      name: entity.name,
      amount: entity.amount,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isRecurring: entity.isRecurring,
      isSaving: entity.isSaving,
      frequency: entity.frequency,
      color: entity.color,
    );
  }
}
