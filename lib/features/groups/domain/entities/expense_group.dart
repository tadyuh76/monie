import 'package:equatable/equatable.dart';

class ExpenseGroup extends Equatable {
  final String id;
  final String adminId;
  final String name;
  final String? description;
  final List<String> members;
  final double totalAmount;
  final bool isSettled;
  final DateTime createdAt;

  const ExpenseGroup({
    required this.id,
    required this.adminId,
    required this.name,
    this.description,
    required this.members,
    required this.totalAmount,
    required this.isSettled,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    adminId,
    name,
    description,
    members,
    totalAmount,
    isSettled,
    createdAt,
  ];
}
