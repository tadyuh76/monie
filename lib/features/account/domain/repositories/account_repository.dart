import 'package:monie/features/account/domain/entities/account.dart';

/// Repository interface for managing accounts
abstract class AccountRepository {
  /// Get all accounts for a user
  Future<List<Account>> getAccounts(String userId);

  /// Get a single account by its ID
  Future<Account?> getAccountById(String accountId);

  /// Create a new account
  Future<Account> createAccount(Account account);

  /// Update an existing account
  Future<Account> updateAccount(Account account);

  /// Delete an account
  Future<void> deleteAccount(String accountId);

  /// Archives or unarchives an account
  Future<Account> toggleArchiveAccount(String accountId, bool archived);

  /// Pins or unpins an account
  Future<Account> togglePinAccount(String accountId, bool pinned);

  /// Updates account balance
  Future<Account> updateBalance(String accountId, double newBalance);

  /// Recalculates account balance
  Future<bool> recalculateAccountBalance(String accountId);
}
