import 'package:injectable/injectable.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/repositories/expense_group_repository.dart';

@injectable
class GetExpenseGroupsUseCase {
  final ExpenseGroupRepository repository;

  GetExpenseGroupsUseCase(this.repository);

  Future<List<ExpenseGroup>> call() async {
    return await repository.getExpenseGroups();
  }
}
