import 'package:monie/features/groups/domain/entities/expense_group.dart';

class ExpenseGroupModel extends ExpenseGroup {
  const ExpenseGroupModel({
    required super.id,
    required super.adminId,
    required super.name,
    super.description,
    required super.members,
    required super.totalAmount,
    required super.isSettled,
    required super.createdAt,
  });

  factory ExpenseGroupModel.fromJson(Map<String, dynamic> json) {
    return ExpenseGroupModel(
      id: json['group_id'],
      adminId: json['admin_id'],
      name: json['name'],
      description: json['description'],
      // Members will be loaded separately
      members: const [],
      // These will be calculated separately
      totalAmount: 0.0,
      isSettled: json['is_settled'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
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
    List<String>? members,
    double? totalAmount,
    bool? isSettled,
    DateTime? createdAt,
  }) {
    return ExpenseGroupModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      totalAmount: totalAmount ?? this.totalAmount,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
