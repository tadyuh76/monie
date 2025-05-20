import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/features/transactions/data/datasources/budget_remote_data_source.dart';
import 'package:monie/features/transactions/data/models/budget_model.dart';
import 'package:monie/features/transactions/domain/entities/budget.dart';
import 'package:monie/features/transactions/domain/repositories/budget_repository.dart';

@Injectable(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDataSource remoteDataSource;

  BudgetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Budget>> getBudgets(String userId) async {
    try {
      return await remoteDataSource.getBudgets(userId);
    } on ServerException catch (e) {
      throw Exception('Failed to get budgets: ${e.message}');
    }
  }

  @override
  Future<Budget?> getBudgetById(String budgetId) async {
    try {
      return await remoteDataSource.getBudgetById(budgetId);
    } on ServerException catch (e) {
      throw Exception('Failed to get budget by ID: ${e.message}');
    }
  }

  @override
  Future<Budget> createBudget(Budget budget) async {
    try {
      final budgetModel = BudgetModel.fromEntity(budget);
      return await remoteDataSource.createBudget(budgetModel);
    } on ServerException catch (e) {
      throw Exception('Failed to create budget: ${e.message}');
    }
  }

  @override
  Future<Budget> updateBudget(Budget budget) async {
    try {
      final budgetModel = BudgetModel.fromEntity(budget);
      return await remoteDataSource.updateBudget(budgetModel);
    } on ServerException catch (e) {
      throw Exception('Failed to update budget: ${e.message}');
    }
  }

  @override
  Future<bool> deleteBudget(String budgetId) async {
    try {
      return await remoteDataSource.deleteBudget(budgetId);
    } on ServerException catch (e) {
      throw Exception('Failed to delete budget: ${e.message}');
    }
  }
}
