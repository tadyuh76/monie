import '../entities/account.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccounts(String userId);
  Future<Account?> getAccountById(String accountId);
  Future<Account> createAccount(Account account);
  Future<Account> updateAccount(Account account);
  Future<bool> deleteAccount(String accountId);
  Future<bool> updateAccountBalance(String accountId, double amount);
  Future<bool> recalculateAccountBalance(String accountId);
}
