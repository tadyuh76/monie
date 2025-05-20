import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String id;
  final String name;
  final double totalAmount;
  final double spentAmount;
  final double remainingAmount;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final String? category;
  final String? categoryId;
  final double progressPercentage;
  final double dailySavingTarget;
  final int daysRemaining;
  final String? userId;
  final bool isRecurring;
  final bool isSaving;
  final String? frequency;
  final String? color;

  const Budget({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.currency,
    required this.startDate,
    required this.endDate,
    this.category,
    this.categoryId,
    required this.progressPercentage,
    required this.dailySavingTarget,
    required this.daysRemaining,
    this.userId,
    this.isRecurring = false,
    this.isSaving = false,
    this.frequency,
    this.color,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    totalAmount,
    spentAmount,
    remainingAmount,
    currency,
    startDate,
    endDate,
    category,
    categoryId,
    progressPercentage,
    dailySavingTarget,
    daysRemaining,
    userId,
    isRecurring,
    isSaving,
    frequency,
    color,
  ];
}
