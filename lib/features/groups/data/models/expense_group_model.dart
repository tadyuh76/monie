import 'package:monie/features/groups/domain/entities/expense_group.dart';

class ExpenseGroupModel extends ExpenseGroup {
  const ExpenseGroupModel({
    required super.id,
    required super.name,
    required super.members,
    required super.totalAmount,
    required super.currency,
    required super.createdAt,
    super.updatedAt,
    required super.isSettled,
  });

  factory ExpenseGroupModel.fromJson(Map<String, dynamic> json) {
    return ExpenseGroupModel(
      id: json['id'],
      name: json['name'],
      members: List<String>.from(json['members']),
      totalAmount: json['totalAmount'].toDouble(),
      currency: json['currency'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isSettled: json['isSettled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members,
      'totalAmount': totalAmount,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isSettled': isSettled,
    };
  }

  factory ExpenseGroupModel.fromEntity(ExpenseGroup entity) {
    return ExpenseGroupModel(
      id: entity.id,
      name: entity.name,
      members: entity.members,
      totalAmount: entity.totalAmount,
      currency: entity.currency,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSettled: entity.isSettled,
    );
  }
}
