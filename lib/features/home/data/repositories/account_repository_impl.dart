import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/home/data/models/account_model.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/domain/repositories/account_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementation of [AccountRepository] using Supabase as the data source
@Injectable(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  final SupabaseClientManager _supabaseClient;
  static const String _tableName = 'accounts';

  AccountRepositoryImpl(this._supabaseClient);

  @override
  Future<List<Account>> getAccounts(String userId) async {
    try {
      final response = await _supabaseClient.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('pinned', ascending: false)
          .order('name');

      return (response as List)
          .map((json) => AccountModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch accounts: ${e.toString()}',
      );
    }
  }

  @override
  Future<Account> createAccount(Account account) async {
    try {
      final response =
          await _supabaseClient.client
              .from(_tableName)
              .insert(AccountModel.fromEntity(account).toJson())
              .select()
              .single();

      return AccountModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('foreign key constraint')) {
        throw ServerException(message: 'Invalid user ID provided');
      } else if (e.message.contains('check constraint')) {
        throw ServerException(message: 'Invalid data format');
      } else {
        throw ServerException(
          message: 'Failed to create account: ${e.message}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to create account: ${e.toString()}',
      );
    }
  }

  @override
  Future<Account> updateAccount(Account account) async {
    try {
      final accountId = account.accountId;
      if (accountId == null) {
        throw ArgumentError('Account ID cannot be null when updating');
      }

      final response =
          await _supabaseClient.client
              .from(_tableName)
              .update(AccountModel.fromEntity(account).toJson())
              .eq('account_id', accountId)
              .select()
              .single();

      return AccountModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('not found')) {
        throw ServerException(message: 'Account not found');
      } else if (e.message.contains('check constraint')) {
        throw ServerException(message: 'Invalid data format');
      } else {
        throw ServerException(
          message: 'Failed to update account: ${e.message}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to update account: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    try {
      await _supabaseClient.client
          .from(_tableName)
          .delete()
          .eq('account_id', accountId);
    } on PostgrestException catch (e) {
      if (e.message.contains('not found')) {
        throw ServerException(message: 'Account not found');
      } else {
        throw ServerException(
          message: 'Failed to delete account: ${e.message}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to delete account: ${e.toString()}',
      );
    }
  }

  @override
  Future<Account> toggleArchiveAccount(String accountId, bool archived) async {
    try {
      final response =
          await _supabaseClient.client
              .from(_tableName)
              .update({'archived': archived})
              .eq('account_id', accountId)
              .select()
              .single();

      return AccountModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('not found')) {
        throw ServerException(message: 'Account not found');
      } else {
        throw ServerException(
          message: 'Failed to update account archive status: ${e.message}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to update account archive status: ${e.toString()}',
      );
    }
  }

  @override
  Future<Account> togglePinAccount(String accountId, bool pinned) async {
    try {
      final response =
          await _supabaseClient.client
              .from(_tableName)
              .update({'pinned': pinned})
              .eq('account_id', accountId)
              .select()
              .single();

      return AccountModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('not found')) {
        throw ServerException(message: 'Account not found');
      } else {
        throw ServerException(
          message: 'Failed to update account pin status: ${e.message}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to update account pin status: ${e.toString()}',
      );
    }
  }

  @override
  Future<Account> updateBalance(String accountId, double newBalance) async {
    try {
      final response =
          await _supabaseClient.client
              .from(_tableName)
              .update({'balance': newBalance})
              .eq('account_id', accountId)
              .select()
              .single();

      return AccountModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('not found')) {
        throw ServerException(message: 'Account not found');
      } else if (e.message.contains('check constraint')) {
        throw ServerException(message: 'Invalid balance format');
      } else {
        throw ServerException(
          message: 'Failed to update account balance: ${e.message}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to update account balance: ${e.toString()}',
      );
    }
  }
}
