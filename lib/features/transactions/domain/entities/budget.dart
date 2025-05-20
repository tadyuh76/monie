import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

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

  Budget({
    String? budgetId,
    required this.userId,
    required this.name,
    required this.amount,
    required this.startDate,
    this.endDate,
    bool? isRecurring,
    bool? isSaving,
    this.frequency,
    this.color,
  }) : budgetId = budgetId ?? const Uuid().v4(),
       isRecurring = isRecurring ?? false,
       isSaving = isSaving ?? false;

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

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      budgetId: map['budget_id'],
      userId: map['user_id'],
      name: map['name'],
      amount: map['amount'] is int ? map['amount'].toDouble() : map['amount'],
      startDate:
          map['start_date'] != null
              ? DateTime.parse(map['start_date'])
              : DateTime.now(),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      isRecurring: map['is_recurring'] ?? false,
      isSaving: map['is_saving'] ?? false,
      frequency: map['frequency'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
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
