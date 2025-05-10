import 'package:monie/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();
  Future<Transaction> getTransactionById(String id);
  Future<List<Transaction>> getTransactionsByType(String type);
  Future<List<Transaction>> getTransactionsByAccountId(String accountId);
  Future<List<Transaction>> getTransactionsByBudgetId(String budgetId);
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
}
