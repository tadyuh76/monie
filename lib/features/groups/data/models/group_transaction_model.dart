import 'package:monie/features/groups/domain/entities/group_transaction.dart';

class GroupTransactionModel extends GroupTransaction {
  const GroupTransactionModel({
    required super.id,
    required super.groupId,
    required super.transactionId,
    required super.title,
    required super.amount,
    super.description,
    required super.date,
    required super.paidByUserId,
    required super.paidByUserName,
    super.categoryName,
    super.color,
    super.status,
    super.approvedAt,
  });

  factory GroupTransactionModel.fromJson(Map<String, dynamic> json) {
    return GroupTransactionModel(
      id: json['group_transaction_id'],
      groupId: json['group_id'],
      transactionId: json['transaction_id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
      paidByUserId: json['user_id'],
      paidByUserName: json['display_name'] ?? json['email'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      categoryName: json['category_name'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_transaction_id': id,
      'group_id': groupId,
      'transaction_id': transactionId,
      'title': title,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'user_id': paidByUserId,
      'display_name': paidByUserName,
      'status': status,
      'approved_at': approvedAt?.toIso8601String(),
      'category_name': categoryName,
      'color': color,
    };
  }

  Map<String, dynamic> toTransactionJson() {
    return {
      'title': title,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'category_name': categoryName,
      'color': color,
    };
  }

  Map<String, dynamic> toGroupTransactionJson() {
    return {
      'group_id': groupId,
      'transaction_id': transactionId,
      'status': status,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  @override
  GroupTransactionModel copyWith({
    String? id,
    String? groupId,
    String? transactionId,
    String? title,
    double? amount,
    String? description,
    DateTime? date,
    String? paidByUserId,
    String? paidByUserName,
    String? status,
    DateTime? approvedAt,
    String? categoryName,
    String? color,
  }) {
    return GroupTransactionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      transactionId: transactionId ?? this.transactionId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      paidByUserName: paidByUserName ?? this.paidByUserName,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      categoryName: categoryName ?? this.categoryName,
      color: color ?? this.color,
    );
  }
}

