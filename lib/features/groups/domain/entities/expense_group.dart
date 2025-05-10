import 'package:equatable/equatable.dart';

class ExpenseGroup extends Equatable {
  final String id;
  final String name;
  final List<String> members;
  final double totalAmount;
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSettled;

  const ExpenseGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
    this.updatedAt,
    required this.isSettled,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    members,
    totalAmount,
    currency,
    createdAt,
    updatedAt,
    isSettled,
  ];
}
