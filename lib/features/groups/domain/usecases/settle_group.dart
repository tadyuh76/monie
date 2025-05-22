import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class SettleGroup {
  final GroupRepository repository;

  SettleGroup({required this.repository});

  Future<Either<Failure, bool>> call(GroupIdParams params) async {
    return await repository.settleGroup(params.groupId);
  }
}

class GroupIdParams extends Equatable {
  final String groupId;

  const GroupIdParams({required this.groupId});

  @override
  List<Object> get props => [groupId];
}
