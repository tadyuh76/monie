import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class AddGroupIncome {
  final GroupRepository repository;

  AddGroupIncome(this.repository);

  Future<Either<Failure, GroupTransaction>> call(
    AddGroupIncomeParams params,
  ) async {
    return await repository.addGroupIncome(
      groupId: params.groupId,
      title: params.title,
      amount: params.amount,
      description: params.description,
      date: params.date,
      categoryName: params.categoryName,
      color: params.color,
    );
  }
}

class AddGroupIncomeParams extends Equatable {
  final String groupId;
  final String title;
  final double amount;
  final String? description;
  final DateTime date;
  final String? categoryName;
  final String? color;

  const AddGroupIncomeParams({
    required this.groupId,
    required this.title,
    required this.amount,
    this.description,
    required this.date,
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
        categoryName,
        color,
      ];
}
