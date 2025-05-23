import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions(String userId);
  Future<Transaction?> getTransactionById(String transactionId);
  Future<List<Transaction>> getTransactionsByAccount(String accountId);
  Future<List<Transaction>> getTransactionsByBudget(String budgetId);
  Future<Transaction> createTransaction(Transaction transaction);
  Future<Transaction> updateTransaction(Transaction transaction);
  Future<bool> deleteTransaction(String transactionId);

  getTransactionsByDateRange(DateTime startDate, DateTime endDate) {}

  getTransactionsByType(String userId, String type) {}
}
