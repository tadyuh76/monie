import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';

class GetAccountByIdUseCase {
  final AccountRepository accountRepository;

  GetAccountByIdUseCase({required this.accountRepository});

  Future<Account?> call(String accountId) async {
    return await accountRepository.getAccountById(accountId);
  }
}
