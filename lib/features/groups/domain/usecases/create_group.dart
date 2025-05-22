import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class CreateGroup {
  final GroupRepository repository;

  CreateGroup({required this.repository});

  Future<Either<Failure, ExpenseGroup>> call(CreateGroupParams params) async {
    return await repository.createGroup(
      name: params.name,
      description: params.description,
    );
  }
}

class CreateGroupParams extends Equatable {
  final String name;
  final String? description;

  const CreateGroupParams({required this.name, this.description});

  @override
  List<Object?> get props => [name, description];
}
