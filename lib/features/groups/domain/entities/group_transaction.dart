import 'package:equatable/equatable.dart';

class GroupTransaction extends Equatable {
  final String id;
  final String groupId;
  final String transactionId;
  final String title;
  final double amount;
  final String? description;
  final DateTime date;
  final String paidByUserId;
  final String paidByUserName;
  final String? categoryName;
  final String? color;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? approvedAt;

  const GroupTransaction({
    required this.id,
    required this.groupId,
    required this.transactionId,
    required this.title,
    required this.amount,
    this.description,
    required this.date,
    required this.paidByUserId,
    required this.paidByUserName,
    this.categoryName,
    this.color,
    this.status = 'pending',
    this.approvedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [
        id,
        groupId,
        transactionId,
        title,
        amount,
        description,
        date,
        paidByUserId,
        paidByUserName,
        categoryName,
        color,
        status,
        approvedAt,
      ];

  GroupTransaction copyWith({
    String? id,
    String? groupId,
    String? transactionId,
    String? title,
    double? amount,
    String? description,
    DateTime? date,
    String? paidByUserId,
    String? paidByUserName,
    String? categoryName,
    String? color,
    String? status,
    DateTime? approvedAt,
  }) {
    return GroupTransaction(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      transactionId: transactionId ?? this.transactionId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      paidByUserName: paidByUserName ?? this.paidByUserName,
      categoryName: categoryName ?? this.categoryName,
      color: color ?? this.color,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}

