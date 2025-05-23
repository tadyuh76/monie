import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';

class ApproveGroupTransaction {
  final GroupRepository repository;

  ApproveGroupTransaction({required this.repository});

  Future<Either<Failure, bool>> call(TransactionApprovalParams params) async {
    return repository.approveGroupTransaction(
      transactionId: params.transactionId,
      approved: params.approved,
    );
  }
}

class TransactionApprovalParams extends Equatable {
  final String transactionId;
  final bool approved;

  const TransactionApprovalParams({
    required this.transactionId,
    required this.approved,
  });

  @override
  List<Object?> get props => [transactionId, approved];
}
