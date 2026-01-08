import 'package:equatable/equatable.dart';

class ExpenseGroup extends Equatable {
  final String id;
  final String adminId;
  final String name;
  final String? description;
  final bool isSettled;
  final DateTime createdAt;
  final int memberCount;
  final double totalAmount;
  final double activeAmount;
  final double settledAmount;

  const ExpenseGroup({
    required this.id,
    required this.adminId,
    required this.name,
    this.description,
    required this.isSettled,
    required this.createdAt,
    required this.memberCount,
    required this.totalAmount,
    required this.activeAmount,
    required this.settledAmount,
  });

  @override
  List<Object?> get props => [
        id,
        adminId,
        name,
        description,
        isSettled,
        createdAt,
        memberCount,
        totalAmount,
        activeAmount,
        settledAmount,
      ];
}
