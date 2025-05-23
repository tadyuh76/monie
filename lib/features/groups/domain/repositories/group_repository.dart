import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';
import 'package:monie/features/groups/data/models/group_member_model.dart';

abstract class GroupRepository {
  /// Get all groups that the current user is a member of
  Future<Either<Failure, List<ExpenseGroup>>> getGroups();

  /// Get a single group by id with all members and transactions
  Future<Either<Failure, ExpenseGroup>> getGroupById(String groupId);

  /// Create a new group
  Future<Either<Failure, ExpenseGroup>> createGroup({
    required String name,
    String? description,
  });

  /// Update an existing group
  Future<Either<Failure, ExpenseGroup>> updateGroup({
    required String groupId,
    String? name,
    String? description,
  });

  /// Delete a group
  Future<Either<Failure, bool>> deleteGroup(String groupId);

  /// Add a member to a group
  Future<Either<Failure, bool>> addMember({
    required String groupId,
    required String email,
    required String role,
  });

  /// Remove a member from a group
  Future<Either<Failure, bool>> removeMember({
    required String groupId,
    required String userId,
  });

  /// Update a member's role in a group
  Future<Either<Failure, bool>> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  });

  /// Calculate debts for a group
  Future<Either<Failure, Map<String, double>>> calculateDebts(String groupId);

  /// Mark a group as settled
  Future<Either<Failure, bool>> settleGroup(String groupId);

  /// Add a new expense to a group
  Future<Either<Failure, GroupTransaction>> addGroupExpense({
    required String groupId,
    required String title,
    required double amount,
    required String description,
    required DateTime date,
    required String paidBy,
    String? categoryName,
    String? color,
  });

  /// Get transactions for a group
  Future<Either<Failure, List<GroupTransaction>>> getGroupTransactions(
    String groupId,
  );

  /// Approve or reject a transaction for a group
  Future<Either<Failure, bool>> approveGroupTransaction({
    required String transactionId,
    required bool approved,
  });

  /// Get members of a group with their details
  Future<Either<Failure, List<GroupMemberModel>>> getGroupMembers(
    String groupId,
  );
}
