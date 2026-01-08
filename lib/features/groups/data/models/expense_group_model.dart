import 'package:monie/features/groups/domain/entities/expense_group.dart';

class ExpenseGroupModel extends ExpenseGroup {
  const ExpenseGroupModel({
    required super.id,
    required super.adminId,
    required super.name,
    super.description,
    required super.isSettled,
    required super.createdAt,
    required super.memberCount,
    required super.totalAmount,
    required super.activeAmount,
    required super.settledAmount,
  });

  factory ExpenseGroupModel.fromJson(Map<String, dynamic> json) {
    return ExpenseGroupModel(
      id: json['group_id'],
      adminId: json['admin_id'],
      name: json['name'],
      description: json['description'],
      isSettled: json['is_settled'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      memberCount: json['member_count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      activeAmount: (json['active_amount'] ?? 0).toDouble(),
      settledAmount: (json['settled_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': id,
      'admin_id': adminId,
      'name': name,
      'description': description,
      'is_settled': isSettled,
    };
  }

  ExpenseGroupModel copyWith({
    String? id,
    String? adminId,
    String? name,
    String? description,
    bool? isSettled,
    DateTime? createdAt,
    int? memberCount,
    double? totalAmount,
    double? activeAmount,
    double? settledAmount,
  }) {
    return ExpenseGroupModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      description: description ?? this.description,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
      totalAmount: totalAmount ?? this.totalAmount,
      activeAmount: activeAmount ?? this.activeAmount,
      settledAmount: settledAmount ?? this.settledAmount,
    );
  }
}

