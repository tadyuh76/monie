import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/features/transactions/data/datasources/account_remote_data_source.dart';
import 'package:monie/features/transactions/data/models/account_model.dart';
import 'package:monie/features/transactions/domain/entities/account.dart';
import 'package:monie/features/transactions/domain/repositories/account_repository.dart';

@Injectable(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;

  AccountRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Account>> getAccounts(String userId) async {
    try {
      return await remoteDataSource.getAccounts(userId);
    } on ServerException catch (e) {
      throw Exception('Failed to get accounts: ${e.message}');
    }
  }

  @override
  Future<Account?> getAccountById(String accountId) async {
    try {
      return await remoteDataSource.getAccountById(accountId);
    } on ServerException catch (e) {
      throw Exception('Failed to get account by ID: ${e.message}');
    }
  }

  @override
  Future<Account> createAccount(Account account) async {
    try {
      final accountModel = AccountModel.fromEntity(account);
      return await remoteDataSource.createAccount(accountModel);
    } on ServerException catch (e) {
      throw Exception('Failed to create account: ${e.message}');
    }
  }

  @override
  Future<Account> updateAccount(Account account) async {
    try {
      final accountModel = AccountModel.fromEntity(account);
      return await remoteDataSource.updateAccount(accountModel);
    } on ServerException catch (e) {
      throw Exception('Failed to update account: ${e.message}');
    }
  }

  @override
  Future<bool> deleteAccount(String accountId) async {
    try {
      return await remoteDataSource.deleteAccount(accountId);
    } on ServerException catch (e) {
      throw Exception('Failed to delete account: ${e.message}');
    }
  }

  @override
  Future<bool> updateAccountBalance(String accountId, double amount) async {
    try {
      return await remoteDataSource.updateAccountBalance(accountId, amount);
    } on ServerException catch (e) {
      throw Exception('Failed to update account balance: ${e.message}');
    }
  }

  @override
  Future<bool> recalculateAccountBalance(String accountId) async {
    try {
      return await remoteDataSource.recalculateAccountBalance(accountId);
    } on ServerException catch (e) {
      throw Exception('Failed to recalculate account balance: ${e.message}');
    }
  }
}
