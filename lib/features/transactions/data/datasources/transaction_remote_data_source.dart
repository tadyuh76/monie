import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/transactions/data/models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getTransactions(String userId);
  Future<TransactionModel?> getTransactionById(String transactionId);
  Future<List<TransactionModel>> getTransactionsByAccount(String accountId);
  Future<List<TransactionModel>> getTransactionsByBudget(String budgetId);
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<bool> deleteTransaction(String transactionId);

  getTransactionsByDateRange(DateTime startDate, DateTime endDate) {}

  getTransactionsByType(String userId, String type) {}
}

@Injectable(as: TransactionRemoteDataSource)
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final SupabaseClientManager _supabaseClientManager;

  TransactionRemoteDataSourceImpl({
    required SupabaseClientManager supabaseClientManager,
  }) : _supabaseClientManager = supabaseClientManager;

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      final response = await _supabaseClientManager.client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get transactions: $e');
    }
  }

  @override
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      final response =
          await _supabaseClientManager.client
              .from('transactions')
              .select()
              .eq('transaction_id', transactionId)
              .single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to get transaction by ID: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByAccount(
    String accountId,
  ) async {
    try {
      final response = await _supabaseClientManager.client
          .from('transactions')
          .select()
          .eq('account_id', accountId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to get transactions by account ID: $e',
      );
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByBudget(
    String budgetId,
  ) async {
    try {
      final response = await _supabaseClientManager.client
          .from('transactions')
          .select()
          .eq('budget_id', budgetId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to get transactions by budget ID: $e',
      );
    }
  }

  @override
  Future<TransactionModel> createTransaction(
    TransactionModel transaction,
  ) async {
    try {
      // Create a map of the transaction data
      final transactionData = transaction.toJson();

      // Ensure we're using the correct field names for the database
      final response =
          await _supabaseClientManager.client
              .from('transactions')
              .insert(transactionData)
              .select()
              .single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw ServerException(message: 'Transaction already exists: $e');
      } else if (e.toString().contains('violates foreign key constraint')) {
        throw ServerException(
          message: 'Invalid reference (account, budget, etc.): $e',
        );
      } else {
        throw ServerException(message: 'Failed to add transaction: $e');
      }
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final response =
          await _supabaseClientManager.client
              .from('transactions')
              .update(transaction.toJson())
              .eq('transaction_id', transaction.transactionId)
              .select()
              .single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to update transaction: $e');
    }
  }

  @override
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _supabaseClientManager.client
          .from('transactions')
          .delete()
          .eq('transaction_id', transactionId);
      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to delete transaction: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabaseClientManager.client
          .from('transactions')
          .select()
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to get transactions by date range: $e',
      );
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByType(
    String userId,
    String type,
  ) async {
    try {
      final response = await _supabaseClientManager.client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('type', type)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get transactions by type: $e');
    }
  }
}
