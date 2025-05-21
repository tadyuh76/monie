import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/account/data/models/account_model.dart';

abstract class AccountRemoteDataSource {
  Future<List<AccountModel>> getAccounts(String userId);
  Future<AccountModel?> getAccountById(String accountId);
  Future<AccountModel> createAccount(AccountModel account);
  Future<AccountModel> updateAccount(AccountModel account);
  Future<bool> deleteAccount(String accountId);
  Future<bool> updateAccountBalance(String accountId, double amount);
  Future<bool> recalculateAccountBalance(String accountId);
}

@Injectable(as: AccountRemoteDataSource)
class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final SupabaseClientManager _supabaseClientManager;

  AccountRemoteDataSourceImpl({
    required SupabaseClientManager supabaseClientManager,
  }) : _supabaseClientManager = supabaseClientManager;

  @override
  Future<List<AccountModel>> getAccounts(String userId) async {
    try {
      final response = await _supabaseClientManager.client
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .order('name');

      return (response as List)
          .map((json) => AccountModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get accounts: $e');
    }
  }

  @override
  Future<AccountModel?> getAccountById(String accountId) async {
    try {
      final response =
          await _supabaseClientManager.client
              .from('accounts')
              .select()
              .eq('account_id', accountId)
              .single();

      return AccountModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to get account by ID: $e');
    }
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final accountData = account.toJson();

      final response =
          await _supabaseClientManager.client
              .from('accounts')
              .insert(accountData)
              .select()
              .single();

      return AccountModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw ServerException(message: 'Account already exists: $e');
      } else {
        throw ServerException(message: 'Failed to create account: $e');
      }
    }
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    try {
      if (account.accountId == null) {
        throw ServerException(
          message: 'Account ID cannot be null when updating an account.',
        );
      }
      final response =
          await _supabaseClientManager.client
              .from('accounts')
              .update(account.toJson())
              .eq('account_id', account.accountId!)
              .select()
              .single();

      return AccountModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to update account: $e');
    }
  }

  @override
  Future<bool> deleteAccount(String accountId) async {
    try {
      await _supabaseClientManager.client
          .from('accounts')
          .delete()
          .eq('account_id', accountId);
      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to delete account: $e');
    }
  }

  @override
  Future<bool> updateAccountBalance(String accountId, double amount) async {
    try {
      // First get the current account to get the balance
      final account = await getAccountById(accountId);
      if (account == null) {
        throw ServerException(message: 'Account not found');
      }

      // Calculate new balance
      final newBalance = account.balance + amount;

      // Update the account with the new balance
      await _supabaseClientManager.client
          .from('accounts')
          .update({'balance': newBalance})
          .eq('account_id', accountId);

      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to update account balance: $e');
    }
  }

  @override
  Future<bool> recalculateAccountBalance(String accountId) async {
    try {
      // First get the current account
      final account = await getAccountById(accountId);
      if (account == null) {
        throw ServerException(message: 'Account not found');
      }

      // Get all transactions for this account
      final response = await _supabaseClientManager.client
          .from('transactions')
          .select()
          .eq('account_id', accountId);

      // Calculate total balance from transactions
      double totalBalance = 0;
      for (final transaction in response as List) {
        final amount = transaction['amount'] as double;
        totalBalance += amount;
      }

      // Update the account with the recalculated balance
      await _supabaseClientManager.client
          .from('accounts')
          .update({'balance': totalBalance})
          .eq('account_id', accountId);

      return true;
    } catch (e) {
      throw ServerException(
        message: 'Failed to recalculate account balance: $e',
      );
    }
  }
}
