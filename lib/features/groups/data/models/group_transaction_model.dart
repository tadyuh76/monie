import 'package:monie/features/groups/domain/entities/group_transaction.dart';

class GroupTransactionModel extends GroupTransaction {
  const GroupTransactionModel({
    required super.id,
    required super.groupId,
    required super.title,
    required super.amount,
    required super.description,
    required super.date,
    required super.paidBy,
    required super.splitWith,
    super.approvalStatus,
    super.approvedAt,
    super.categoryName,
    super.color,
  });

  factory GroupTransactionModel.fromJson(Map<String, dynamic> json) {
    return GroupTransactionModel(
      id: json['transaction_id'],
      groupId: json['group_id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      paidBy: json['paid_by'] ?? json['user_id'],
      // Convert split_with from JSON array to List<String> if available
      splitWith:
          json['split_with'] != null
              ? (json['split_with'] as List).map((e) => e.toString()).toList()
              : [],
      approvalStatus: json['status'] ?? json['approval_status'] ?? 'pending',
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      categoryName: json['category_name'],
      color: json['color'],
    );
  }

  // Method to create from separate transaction and group_transaction data
  factory GroupTransactionModel.fromTransactionAndGroup(
    Map<String, dynamic> transaction,
    Map<String, dynamic> groupTransaction,
  ) {
    return GroupTransactionModel(
      id: transaction['transaction_id'],
      groupId: groupTransaction['group_id'],
      title: transaction['title'],
      amount: (transaction['amount'] as num).toDouble(),
      description: transaction['description'] ?? '',
      date: DateTime.parse(transaction['date']),
      paidBy: transaction['user_id'],
      // This would need to be provided separately
      splitWith: [],
      approvalStatus: groupTransaction['status'] ?? 'pending',
      approvedAt:
          groupTransaction['approved_at'] != null
              ? DateTime.parse(groupTransaction['approved_at'])
              : null,
      categoryName: transaction['category_name'],
      color: transaction['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': id,
      'group_id': groupId,
      'title': title,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'paid_by': paidBy,
      'split_with': splitWith,
      'approval_status': approvalStatus,
      'approved_at': approvedAt?.toIso8601String(),
      'category_name': categoryName,
      'color': color,
    };
  }

  Map<String, dynamic> toTransactionJson() {
    return {
      'transaction_id': id,
      'title': title,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'user_id': paidBy,
      'type': 'expense',
      'category_name': categoryName,
      'color': color,
    };
  }

  Map<String, dynamic> toGroupTransactionJson() {
    return {
      'group_id': groupId,
      'transaction_id': id,
      'status': approvalStatus,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  @override
  GroupTransactionModel copyWith({
    String? id,
    String? groupId,
    String? title,
    double? amount,
    String? description,
    DateTime? date,
    String? paidBy,
    List<String>? splitWith,
    String? approvalStatus,
    DateTime? approvedAt,
    String? categoryName,
    String? color,
  }) {
    return GroupTransactionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      paidBy: paidBy ?? this.paidBy,
      splitWith: splitWith ?? this.splitWith,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedAt: approvedAt ?? this.approvedAt,
      categoryName: categoryName ?? this.categoryName,
      color: color ?? this.color,
    );
  }
}
