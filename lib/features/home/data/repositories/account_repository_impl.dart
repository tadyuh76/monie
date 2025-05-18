import 'package:injectable/injectable.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/home/data/models/account_model.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/domain/repositories/account_repository.dart';

@Injectable(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  @override
  Future<List<Account>> getAccounts() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.accounts;
  }

  @override
  Future<Account> getAccountById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    final account = MockData.accounts.firstWhere(
      (account) => account.id == id,
      orElse: () => throw Exception('Account not found'),
    );

    return account;
  }

  @override
  Future<void> addAccount(Account account) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    final accountModel = AccountModel.fromEntity(account);
    MockData.accounts.add(accountModel);
  }

  @override
  Future<void> updateAccount(Account account) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    final index = MockData.accounts.indexWhere((a) => a.id == account.id);

    if (index >= 0) {
      MockData.accounts[index] = AccountModel.fromEntity(account);
    } else {
      throw Exception('Account not found');
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    MockData.accounts.removeWhere((account) => account.id == id);
  }
}
