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
  Future<List<Transaction>> getTransactions() async {
    try {
      return await remoteDataSource.getTransactions();
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions: ${e.message}');
    }
  }

  @override
  Future<Transaction> getTransactionById(String id) async {
    try {
      return await remoteDataSource.getTransactionById(id);
    } on ServerException catch (e) {
      throw Exception('Failed to get transaction by ID: ${e.message}');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByType(String type) async {
    try {
      return await remoteDataSource.getTransactionsByType(type);
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions by type: ${e.message}');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByAccountId(String accountId) async {
    try {
      return await remoteDataSource.getTransactionsByAccountId(accountId);
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions by account ID: ${e.message}');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByBudgetId(String budgetId) async {
    try {
      return await remoteDataSource.getTransactionsByBudgetId(budgetId);
    } on ServerException catch (e) {
      throw Exception('Failed to get transactions by budget ID: ${e.message}');
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
  Future<void> addTransaction(Transaction transaction) async {
    try {
      final transactionModel = TransactionModel.fromEntity(transaction);
      await remoteDataSource.addTransaction(transactionModel);
    } on ServerException catch (e) {
      throw Exception('Failed to add transaction: ${e.message}');
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final transactionModel = TransactionModel.fromEntity(transaction);
      await remoteDataSource.updateTransaction(transactionModel);
    } on ServerException catch (e) {
      throw Exception('Failed to update transaction: ${e.message}');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await remoteDataSource.deleteTransaction(id);
    } on ServerException catch (e) {
      throw Exception('Failed to delete transaction: ${e.message}');
    }
  }
}
