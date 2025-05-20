import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
import 'package:monie/features/groups/data/models/expense_group_model.dart';
import 'package:monie/features/home/data/models/account_model.dart';
import 'package:monie/features/transactions/data/models/transaction_model.dart';

class MockData {
  // Mock Accounts
  static List<AccountModel> accounts = [
    AccountModel(
      id: '1',
      name: 'Bank',
      type: 'bank',
      balance: 3200.0,
      currency: 'USD',
      transactionCount: 7,
    ),
    AccountModel(
      id: '2',
      name: 'Cash',
      type: 'cash',
      balance: 140.0,
      currency: 'USD',
      transactionCount: 2,
    ),
  ];

  // Mock Transactions
  static List<TransactionModel> transactions = [
    // Expense transactions
    TransactionModel(
      id: '1',
      description: 'Weekly grocery shopping',
      amount: -60.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 1)),
      categoryName: 'Groceries',
      categoryColor: TransactionCategories.getCategoryColorByName('Groceries'),
      accountId: '2',
      title: 'Groceries',
    ),
    TransactionModel(
      id: '2',
      description: 'Monthly rent payment',
      amount: -1200.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 3)),
      categoryName: 'Rent',
      categoryColor: TransactionCategories.getCategoryColorByName('Rent'),
      accountId: '1',
      title: 'Rent',
    ),
    TransactionModel(
      id: '3',
      description: 'Movie night with friends',
      amount: -35.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 5)),
      categoryName: 'Movies',
      categoryColor: TransactionCategories.getCategoryColorByName('Movies'),
      accountId: '1',
      budgetId: '1',
      title: 'Movies',
    ),
    TransactionModel(
      id: '4',
      description: 'Electricity bill for April',
      amount: -85.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 7)),
      categoryName: 'Electricity',
      categoryColor: TransactionCategories.getCategoryColorByName(
        'Electricity',
      ),
      accountId: '1',
      title: 'Electricity',
    ),
    TransactionModel(
      id: '5',
      description: 'New shirt for work',
      amount:  -45.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 8)),
      categoryName: 'Clothing',
      categoryColor: TransactionCategories.getCategoryColorByName('Clothing'),
      accountId: '1',
      title: 'Clothing',
    ),

    // Income transactions
    TransactionModel(
      id: '6',
      description: 'Monthly salary payment',
      amount: 3500.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 2)),
      categoryName: 'Salary',
      categoryColor: TransactionCategories.getCategoryColorByName('Salary'),
      accountId: '1',
      title: 'Salary',
    ),
    TransactionModel(
      id: '7',
      description: 'Freelance web development project',
      amount: 850.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 10)),
      categoryName: 'Freelance',
      categoryColor: TransactionCategories.getCategoryColorByName('Freelance'),
      accountId: '1',
      title: 'Freelance',
    ),
    TransactionModel(
      id: '8',
      description: 'Stock dividend payment',
      amount: 120.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 15)),
      categoryName: 'Dividends',
      categoryColor: TransactionCategories.getCategoryColorByName('Dividends'),
      accountId: '1',
      title: 'Dividends',
    ),
    TransactionModel(
      id: '9',
      description: 'Cash gift from mom',
      amount: 200.0,
      userId: 'user1',
      date: DateTime.now().subtract(const Duration(days: 20)),
      categoryName: 'Gift',
      categoryColor: TransactionCategories.getCategoryColorByName('Gift'),
      accountId: '2',
      title: 'Gift',
    ),
  ];

  // Mock Budgets
  static List<BudgetModel> budgets = [
    BudgetModel(
      id: '1',
      name: 'trip',
      totalAmount: 50.0,
      spentAmount: 35.0,
      remainingAmount: 15.0,
      currency: 'USD',
      startDate: DateTime(2023, 4, 1),
      endDate: DateTime(2023, 5, 15),
      progressPercentage: 70.0,
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
