import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class AddMember {
  final GroupRepository repository;

  AddMember({required this.repository});

  Future<Either<Failure, bool>> call(AddMemberParams params) async {
    return await repository.addMember(
      groupId: params.groupId,
      email: params.email,
      role: params.role,
    );
  }
}

class AddMemberParams extends Equatable {
  final String groupId;
  final String email;
  final String role;

  const AddMemberParams({
    required this.groupId,
    required this.email,
    required this.role,
  });

  @override
  List<Object> get props => [groupId, email, role];
}
