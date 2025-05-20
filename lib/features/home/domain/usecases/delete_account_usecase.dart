import 'package:injectable/injectable.dart';
import 'package:monie/features/home/domain/repositories/account_repository.dart';

@injectable
class DeleteAccountUseCase {
  final AccountRepository repository;

  DeleteAccountUseCase(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteAccount(id);
  }
}
