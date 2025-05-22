import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/groups/data/datasources/group_remote_datasource.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';
import 'package:monie/features/groups/data/models/group_member_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource dataSource;

  GroupRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ExpenseGroup>>> getGroups() async {
    try {
      final groups = await dataSource.getGroups();
      return Right(groups);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseGroup>> getGroupById(String groupId) async {
    try {
      final group = await dataSource.getGroupById(groupId);
      return Right(group);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseGroup>> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final group = await dataSource.createGroup(
        name: name,
        description: description,
      );
      return Right(group);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseGroup>> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    try {
      final group = await dataSource.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
      );
      return Right(group);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteGroup(String groupId) async {
    try {
      final result = await dataSource.deleteGroup(groupId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> addMember({
    required String groupId,
    required String email,
    required String role,
  }) async {
    try {
      final result = await dataSource.addMember(
        groupId: groupId,
        email: email,
        role: role,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final result = await dataSource.removeMember(
        groupId: groupId,
        userId: userId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  }) async {
    try {
      final result = await dataSource.updateMemberRole(
        groupId: groupId,
        userId: userId,
        role: role,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> calculateDebts(
    String groupId,
  ) async {
    try {
      final debts = await dataSource.calculateDebts(groupId);
      return Right(debts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> settleGroup(String groupId) async {
    try {
      final result = await dataSource.settleGroup(groupId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupTransaction>> addGroupExpense({
    required String groupId,
    required String title,
    required double amount,
    required String description,
    required DateTime date,
    required String paidBy,
    String? categoryName,
    String? color,
  }) async {
    try {
      final transaction = await dataSource.addGroupExpense(
        groupId: groupId,
        title: title,
        amount: amount,
        description: description,
        date: date,
        paidBy: paidBy,
        categoryName: categoryName,
        color: color,
      );
      return Right(transaction);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to add expense: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<GroupTransaction>>> getGroupTransactions(
    String groupId,
  ) async {
    try {
      final transactions = await dataSource.getGroupTransactions(groupId);
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to get transactions: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> approveGroupTransaction({
    required String transactionId,
    required bool approved,
  }) async {
    try {
      final result = await dataSource.approveGroupTransaction(
        transactionId: transactionId,
        approved: approved,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to approve transaction: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<GroupMemberModel>>> getGroupMembers(
    String groupId,
  ) async {
    try {
      final members = await dataSource.getGroupMembers(groupId);
      return Right(members);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
