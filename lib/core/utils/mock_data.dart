import 'package:monie/features/home/data/models/account_model.dart';
import 'package:monie/features/transactions/data/models/transaction_model.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
import 'package:monie/features/groups/data/models/expense_group_model.dart';

class MockData {
  // Mock Accounts
  static List<AccountModel> accounts = [
    AccountModel(
      id: '1',
      name: 'Bank',
      type: 'bank',
      balance: 238.0,
      currency: 'USD',
      transactionCount: 2,
    ),
    AccountModel(
      id: '2',
      name: 'Cash',
      type: 'cash',
      balance: -60.0,
      currency: 'USD',
      transactionCount: 1,
    ),
  ];

  // Mock Transactions
  static List<TransactionModel> transactions = [
    TransactionModel(
      id: '1',
      title: 'Groceries',
      amount: 60.0,
      currency: 'USD',
      date: DateTime(2023, 4, 30),
      category: 'Food',
      type: 'expense',
      accountId: '2',
      iconPath: 'assets/icons/groceries.png',
    ),
    TransactionModel(
      id: '2',
      title: 'thhy',
      amount: 288.0,
      currency: 'USD',
      date: DateTime(2023, 4, 27),
      category: 'Income',
      type: 'income',
      accountId: '1',
    ),
    TransactionModel(
      id: '3',
      title: 'test',
      amount: 50.0,
      currency: 'USD',
      date: DateTime(2023, 4, 27),
      category: 'Food',
      type: 'expense',
      budgetId: '1',
      iconPath: 'assets/icons/groceries.png',
    ),
  ];

  // Mock Budgets
  static List<BudgetModel> budgets = [
    BudgetModel(
      id: '1',
      name: 'trip',
      totalAmount: 50.0,
      spentAmount: 0.0,
      remainingAmount: 50.0,
      currency: 'USD',
      startDate: DateTime(2023, 4, 1),
      endDate: DateTime(2023, 5, 15),
      progressPercentage: 0.0,
      dailySavingTarget: 8.33,
      daysRemaining: 6,
    ),
  ];

  // Mock Expense Groups
  static List<ExpenseGroupModel> expenseGroups = [
    ExpenseGroupModel(
      id: '1',
      name: 'Trip to Paris',
      members: ['John', 'Jane', 'Bob'],
      totalAmount: 450.0,
      currency: 'USD',
      createdAt: DateTime(2023, 4, 15),
      isSettled: false,
    ),
  ];
}
