import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class GetGroupById {
  final GroupRepository repository;

  GetGroupById({required this.repository});

  Future<Either<Failure, ExpenseGroup>> call(GroupIdParams params) async {
    return await repository.getGroupById(params.groupId);
  }
}

class GroupIdParams extends Equatable {
  final String groupId;

  const GroupIdParams({required this.groupId});

  @override
  List<Object> get props => [groupId];
}
