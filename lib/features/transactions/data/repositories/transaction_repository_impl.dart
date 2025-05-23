import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:monie/features/transactions/data/models/transaction_model.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@Injectable(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Transaction>> getTransactions(String userId) async {
    try {
      return await remoteDataSource.getTransactions(userId);
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions: ${e.message}');
    }
  }

  @override
  Future<Transaction?> getTransactionById(String transactionId) async {
    try {
      return await remoteDataSource.getTransactionById(transactionId);
    } on ServerException catch (e) {
      throw Exception('Failed to get transaction by ID: ${e.message}');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByAccount(String accountId) async {
    try {
      return await remoteDataSource.getTransactionsByAccount(accountId);
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions by account ID: ${e.message}');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByBudget(String budgetId) async {
    try {
      return await remoteDataSource.getTransactionsByBudget(budgetId);
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions by budget ID: ${e.message}');
    }
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final transactionModel = TransactionModel.fromEntity(transaction);
      return await remoteDataSource.createTransaction(transactionModel);
    } on ServerException catch (e) {
      throw Exception('Failed to create transaction: ${e.message}');
    }
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final transactionModel = TransactionModel.fromEntity(transaction);
      return await remoteDataSource.updateTransaction(transactionModel);
    } on ServerException catch (e) {
      throw Exception('Failed to update transaction: ${e.message}');
    }
  }

  @override
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      return await remoteDataSource.deleteTransaction(transactionId);
    } on ServerException catch (e) {
      throw Exception('Failed to delete transaction: ${e.message}');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await remoteDataSource.getTransactionsByDateRange(
        startDate,
        endDate,
      );
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions by date range: ${e.message}');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByType(
    String userId,
    String type,
  ) async {
    try {
      return await remoteDataSource.getTransactionsByType(userId, type);
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions by type: ${e.message}');
    }
  }
}
