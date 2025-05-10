import 'package:injectable/injectable.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/transactions/data/models/transaction_model.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@Injectable(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  @override
  Future<List<Transaction>> getTransactions() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.transactions;
  }

  @override
  Future<Transaction> getTransactionById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    final transaction = MockData.transactions.firstWhere(
      (transaction) => transaction.id == id,
      orElse: () => throw Exception('Transaction not found'),
    );

    return transaction;
  }

  @override
  Future<List<Transaction>> getTransactionsByType(String type) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    return MockData.transactions
        .where((transaction) => transaction.type == type)
        .toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByAccountId(String accountId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    return MockData.transactions
        .where((transaction) => transaction.accountId == accountId)
        .toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByBudgetId(String budgetId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    return MockData.transactions
        .where((transaction) => transaction.budgetId == budgetId)
        .toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    return MockData.transactions.where((transaction) {
      return transaction.date.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    final transactionModel = TransactionModel.fromEntity(transaction);
    MockData.transactions.add(transactionModel);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    final index = MockData.transactions.indexWhere(
      (t) => t.id == transaction.id,
    );

    if (index >= 0) {
      MockData.transactions[index] = TransactionModel.fromEntity(transaction);
    } else {
      throw Exception('Transaction not found');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    MockData.transactions.removeWhere((transaction) => transaction.id == id);
  }
}
