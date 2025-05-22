import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class AddGroupExpense {
  final GroupRepository repository;

  AddGroupExpense({required this.repository});

  Future<Either<Failure, GroupTransaction>> call(
    AddGroupExpenseParams params,
  ) async {
    return repository.addGroupExpense(
      groupId: params.groupId,
      title: params.title,
      amount: params.amount,
      description: params.description,
      date: params.date,
      paidBy: params.paidBy,
      categoryName: params.categoryName,
      color: params.color,
    );
  }
}

class AddGroupExpenseParams extends Equatable {
  final String groupId;
  final String title;
  final double amount;
  final String description;
  final DateTime date;
  final String paidBy;
  final String? categoryName;
  final String? color;

  const AddGroupExpenseParams({
    required this.groupId,
    required this.title,
    required this.amount,
    required this.description,
    required this.date,
    required this.paidBy,
    this.categoryName,
    this.color,
  });

  @override
  List<Object?> get props => [
    groupId,
    title,
    amount,
    description,
    date,
    paidBy,
    categoryName,
    color,
  ];
}
