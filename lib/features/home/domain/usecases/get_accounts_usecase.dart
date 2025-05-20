import 'package:injectable/injectable.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

@injectable
class GetAccountsUseCase {
  final AccountRepository repository;

  GetAccountsUseCase(this.repository);

  Future<List<Account>> call(String userId) async {
    return await repository.getAccounts(userId);
  }
}
