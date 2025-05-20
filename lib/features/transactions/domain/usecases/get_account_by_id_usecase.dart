import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/account.dart';
import 'package:monie/features/transactions/domain/repositories/account_repository.dart';

@injectable
class GetAccountByIdUseCase {
  final AccountRepository repository;

  GetAccountByIdUseCase(this.repository);

  Future<Account?> call(String accountId) async {
    return await repository.getAccountById(accountId);
  }
}
