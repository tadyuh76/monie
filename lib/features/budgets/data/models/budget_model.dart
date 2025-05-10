import 'package:monie/features/budgets/domain/entities/budget.dart';

class BudgetModel extends Budget {
  const BudgetModel({
    required super.id,
    required super.name,
    required super.totalAmount,
    required super.spentAmount,
    required super.remainingAmount,
    required super.currency,
    required super.startDate,
    required super.endDate,
    super.category,
    required super.progressPercentage,
    required super.dailySavingTarget,
    required super.daysRemaining,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      name: json['name'],
      totalAmount: json['totalAmount'].toDouble(),
      spentAmount: json['spentAmount'].toDouble(),
      remainingAmount: json['remainingAmount'].toDouble(),
      currency: json['currency'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      category: json['category'],
      progressPercentage: json['progressPercentage'].toDouble(),
      dailySavingTarget: json['dailySavingTarget'].toDouble(),
      daysRemaining: json['daysRemaining'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'spentAmount': spentAmount,
      'remainingAmount': remainingAmount,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'category': category,
      'progressPercentage': progressPercentage,
      'dailySavingTarget': dailySavingTarget,
      'daysRemaining': daysRemaining,
    };
  }

  factory BudgetModel.fromEntity(Budget entity) {
    return BudgetModel(
      id: entity.id,
      name: entity.name,
      totalAmount: entity.totalAmount,
      spentAmount: entity.spentAmount,
      remainingAmount: entity.remainingAmount,
      currency: entity.currency,
      startDate: entity.startDate,
      endDate: entity.endDate,
      category: entity.category,
      progressPercentage: entity.progressPercentage,
      dailySavingTarget: entity.dailySavingTarget,
      daysRemaining: entity.daysRemaining,
    );
  }
}
