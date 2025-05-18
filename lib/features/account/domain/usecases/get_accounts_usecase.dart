import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';

class GetAccountsUseCase {
  final AccountRepository repository;
  GetAccountsUseCase(this.repository);

  Future<List<Account>> call() async {
    return await repository.getAccounts();
  }
} 