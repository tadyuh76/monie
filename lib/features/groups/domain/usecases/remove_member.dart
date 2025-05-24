import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class RemoveMember {
  final GroupRepository repository;

  RemoveMember({required this.repository});

  Future<Either<Failure, bool>> call(RemoveMemberParams params) async {
    return await repository.removeMember(
      groupId: params.groupId,
      userId: params.userId,
    );
  }
}

class RemoveMemberParams extends Equatable {
  final String groupId;
  final String userId;

  const RemoveMemberParams({required this.groupId, required this.userId});

  @override
  List<Object> get props => [groupId, userId];
}
