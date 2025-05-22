import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/data/models/group_member_model.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class GetGroupMembers {
  final GroupRepository repository;

  GetGroupMembers({required this.repository});

  Future<Either<Failure, List<GroupMemberModel>>> call(
    GroupIdParams params,
  ) async {
    return repository.getGroupMembers(params.groupId);
  }
}

class GroupIdParams extends Equatable {
  final String groupId;

  const GroupIdParams({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}
