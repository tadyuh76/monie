import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/repositories/account_repository.dart';

@injectable
class DeleteAccountUseCase {
  final AccountRepository repository;

  DeleteAccountUseCase(this.repository);

  Future<bool> call(String accountId) async {
    return await repository.deleteAccount(accountId);
  }
}
