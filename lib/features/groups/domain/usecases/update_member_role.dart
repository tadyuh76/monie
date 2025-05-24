import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class UpdateMemberRole {
  final GroupRepository repository;

  UpdateMemberRole({required this.repository});

  Future<Either<Failure, bool>> call(UpdateMemberRoleParams params) async {
    return await repository.updateMemberRole(
      groupId: params.groupId,
      userId: params.userId,
      role: params.role,
    );
  }
}

class UpdateMemberRoleParams extends Equatable {
  final String groupId;
  final String userId;
  final String role;

  const UpdateMemberRoleParams({
    required this.groupId,
    required this.userId,
    required this.role,
  });

  @override
  List<Object> get props => [groupId, userId, role];
}
