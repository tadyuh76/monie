import 'package:injectable/injectable.dart';
import '../../domain/entities/account.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';

@injectable
class GetAccountsUseCase {
  final AccountRepository repository;

  GetAccountsUseCase(this.repository);

  Future<List<Account>> call(String userId) async {
    return await repository.getAccounts(userId);
  }
}
