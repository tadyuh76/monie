import 'package:monie/features/groups/domain/entities/expense_group.dart';

abstract class ExpenseGroupRepository {
  Future<List<ExpenseGroup>> getExpenseGroups();
  Future<ExpenseGroup> getExpenseGroupById(String id);
  Future<void> addExpenseGroup(ExpenseGroup group);
  Future<void> updateExpenseGroup(ExpenseGroup group);
  Future<void> deleteExpenseGroup(String id);
  Future<void> settleExpenseGroup(String id);
}
