import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class GetGroupTransactions {
  final GroupRepository repository;

  GetGroupTransactions({required this.repository});

  Future<Either<Failure, List<GroupTransaction>>> call(
    GroupIdParams params,
  ) async {
    return repository.getGroupTransactions(params.groupId);
  }
}

class GroupIdParams extends Equatable {
  final String groupId;

  const GroupIdParams({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}
