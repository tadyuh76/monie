import 'package:equatable/equatable.dart';

class GroupTransaction extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String description;
  final DateTime date;
  final String paidBy;
  final List<String> splitWith;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final DateTime? approvedAt;
  final String? categoryName;
  final String? color;

  const GroupTransaction({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.description,
    required this.date,
    required this.paidBy,
    required this.splitWith,
    this.approvalStatus = 'pending',
    this.approvedAt,
    this.categoryName,
    this.color,
  });

  @override
  List<Object?> get props => [
    id,
    groupId,
    title,
    amount,
    description,
    date,
    paidBy,
    splitWith,
    approvalStatus,
    approvedAt,
    categoryName,
    color,
  ];

  GroupTransaction copyWith({
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
    return GroupTransaction(
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
