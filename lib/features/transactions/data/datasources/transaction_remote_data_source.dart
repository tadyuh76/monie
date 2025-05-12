import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/transactions/data/models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> getTransactionById(String id);
  Future<List<TransactionModel>> getTransactionsByType(String type);
  Future<List<TransactionModel>> getTransactionsByAccountId(String accountId);
  Future<List<TransactionModel>> getTransactionsByBudgetId(String budgetId);
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

@Injectable(as: TransactionRemoteDataSource)
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final SupabaseClientManager _supabaseClientManager;

  TransactionRemoteDataSourceImpl({
    required SupabaseClientManager supabaseClientManager,
  }) : _supabaseClientManager = supabaseClientManager;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _supabaseClientManager.client
          .from('transactions')
          .select()
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get transactions: $e');
    }
  }

  @override
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final response =
          await _supabaseClientManager.client
              .from('transactions')
              .select()
              .eq('transaction_id', id)
              .single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to get transaction by ID: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByType(String type) async {
    try {
      // Determine if we need to filter by amount sign
      bool isIncome = type == 'income';

      final query = _supabaseClientManager.client.from('transactions').select();

      // Apply different filters based on type
      if (isIncome) {
        query.gte('amount', 0);
      } else {
        query.lt('amount', 0);
      }

      final response = await query.order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get transactions by type: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByAccountId(
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
  Future<List<TransactionModel>> getTransactionsByBudgetId(
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
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      // Create a map of the transaction data
      final transactionData = transaction.toJson();

      // Log the transaction data for debugging

      // Ensure we're using the correct field names for the database
      final response =
          await _supabaseClientManager.client
              .from('transactions')
              .insert(transactionData)
              .select();

      if ((response.isEmpty)) {}
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw ServerException(message: 'Transaction already exists: $e');
      } else if (e.toString().contains('violates foreign key constraint')) {
        throw ServerException(
          message: 'Invalid reference (category, user, etc.): $e',
        );
      } else {
        throw ServerException(message: 'Failed to add transaction: $e');
      }
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _supabaseClientManager.client
          .from('transactions')
          .update(transaction.toJson())
          .eq('transaction_id', transaction.id);
    } catch (e) {
      throw ServerException(message: 'Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _supabaseClientManager.client
          .from('transactions')
          .delete()
          .eq('transaction_id', id);
    } catch (e) {
      throw ServerException(message: 'Failed to delete transaction: $e');
    }
  }
}
