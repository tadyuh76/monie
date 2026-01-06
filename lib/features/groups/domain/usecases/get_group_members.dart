import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/entities/group_member.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class GetGroupMembers {
  final GroupRepository repository;

  GetGroupMembers(this.repository);

  Future<Either<Failure, List<GroupMember>>> call(
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
