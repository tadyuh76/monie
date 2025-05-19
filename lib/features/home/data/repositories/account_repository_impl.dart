import 'package:injectable/injectable.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/home/data/models/account_model.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/domain/repositories/account_repository.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/supabase_client.dart';

@Injectable(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  @override
  Future<List<Account>> getAccounts() async {
    try {
      final response = await  SupabaseClientManager.instance.client
          .from('accounts')
          .select();

      return (response as List)
          .map((json) => AccountModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to get transactions by account ID: $e',
      );
    }
  }

  @override
  Future<Account> getAccountById(String id) async {
    try {
      final response = await SupabaseClientManager.instance.client
          .from('accounts')
          .select()
          .eq('id', id);
      return (response as List).firstWhere((acc) => acc.id == id);
    } catch (e) {
      throw ServerException(
        message: 'Account not found',
      );
    }
  }

  @override
  Future<void> addAccount(Account account) async {
    try {
      final accountModel = AccountModel.fromEntity(account);
      final response = await SupabaseClientManager.instance.client
          .from('accounts')
          .insert(accountModel.toJson())
          .select();
      print('Account added successfully');
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw ServerException(message: 'Account already exists: $e');
      } else if (e.toString().contains('violates foreign key constraint')) {
        throw ServerException(
          message: 'Invalid reference: $e',
        );
      } else {
        throw ServerException(message: 'Failed to add account: $e');
      }
    }

  }

  @override
  Future<void> updateAccount(Account account) async {
    try {
      final accountModel = AccountModel.fromEntity(account);
      await SupabaseClientManager.instance.client
          .from('accounts')
          .update(accountModel.toJson())
          .eq('id', account.id ?? -1);
    } catch (e) {
      throw ServerException(message: 'Failed to update account: $e');
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await SupabaseClientManager.instance.client
          .from('accounts')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw ServerException(message: 'Failed to delete account: $e');
    }
  }
}
