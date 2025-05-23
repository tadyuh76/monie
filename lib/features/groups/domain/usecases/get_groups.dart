import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class GetGroups {
  final GroupRepository repository;

  GetGroups({required this.repository});

  Future<Either<Failure, List<ExpenseGroup>>> call() async {
    return await repository.getGroups();
  }
}
