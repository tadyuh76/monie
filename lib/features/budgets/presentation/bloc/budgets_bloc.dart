import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/domain/usecases/add_budget_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/get_active_budgets_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/update_budget_usecase.dart';

// Events
abstract class BudgetsEvent extends Equatable {
  const BudgetsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgets extends BudgetsEvent {
  const LoadBudgets();
}

class LoadActiveBudgets extends BudgetsEvent {
  const LoadActiveBudgets();
}

class AddBudget extends BudgetsEvent {
  final Budget budget;

  const AddBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class UpdateBudget extends BudgetsEvent {
  final Budget budget;

  const UpdateBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class DeleteBudget extends BudgetsEvent {
  final String budgetId;

  const DeleteBudget(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

// States
abstract class BudgetsState extends Equatable {
  const BudgetsState();

  @override
  List<Object?> get props => [];
}

class BudgetsInitial extends BudgetsState {
  const BudgetsInitial();
}

class BudgetsLoading extends BudgetsState {
  const BudgetsLoading();
}

class BudgetsLoaded extends BudgetsState {
  final List<Budget> budgets;
  final double totalBudgeted;
  final double totalSpent;
  final double totalRemaining;
  final bool
  isActive; // Whether this is showing all budgets or just active ones

  const BudgetsLoaded({
    required this.budgets,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.totalRemaining,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [
    budgets,
    totalBudgeted,
    totalSpent,
    totalRemaining,
    isActive,
  ];
}

class BudgetAdded extends BudgetsState {
  final Budget budget;

  const BudgetAdded(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetUpdated extends BudgetsState {
  final Budget budget;

  const BudgetUpdated(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetDeleted extends BudgetsState {
  final String budgetId;

  const BudgetDeleted(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class BudgetsError extends BudgetsState {
  final String message;

  const BudgetsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
@injectable
class BudgetsBloc extends Bloc<BudgetsEvent, BudgetsState> {
  final GetBudgetsUseCase getBudgetsUseCase;
  final GetActiveBudgetsUseCase getActiveBudgetsUseCase;
  final AddBudgetUseCase addBudgetUseCase;
  final UpdateBudgetUseCase updateBudgetUseCase;
  final DeleteBudgetUseCase deleteBudgetUseCase;

  BudgetsBloc({
    required this.getBudgetsUseCase,
    required this.getActiveBudgetsUseCase,
    required this.addBudgetUseCase,
    required this.updateBudgetUseCase,
    required this.deleteBudgetUseCase,
  }) : super(const BudgetsInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<LoadActiveBudgets>(_onLoadActiveBudgets);
    on<AddBudget>(_onAddBudget);
    on<UpdateBudget>(_onUpdateBudget);
    on<DeleteBudget>(_onDeleteBudget);
  }

  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<BudgetsState> emit,
  ) async {
    emit(const BudgetsLoading());

    try {
      final budgets = await getBudgetsUseCase();

      // Calculate totals using extension methods
      final totalBudgeted = budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.amount,
      );

      final totalSpent = budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.spentAmount,
      );

      final totalRemaining = budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.remainingAmount,
      );

      emit(
        BudgetsLoaded(
          budgets: budgets,
          totalBudgeted: totalBudgeted,
          totalSpent: totalSpent,
          totalRemaining: totalRemaining,
          isActive: false,
        ),
      );
    } catch (e) {
      emit(BudgetsError(e.toString()));
    }
  }

  Future<void> _onLoadActiveBudgets(
    LoadActiveBudgets event,
    Emitter<BudgetsState> emit,
  ) async {
    emit(const BudgetsLoading());

    try {
      final budgets = await getActiveBudgetsUseCase();

      // Calculate totals using extension methods
      final totalBudgeted = budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.amount,
      );

      final totalSpent = budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.spentAmount,
      );

      final totalRemaining = budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.remainingAmount,
      );

      emit(
        BudgetsLoaded(
          budgets: budgets,
          totalBudgeted: totalBudgeted,
          totalSpent: totalSpent,
          totalRemaining: totalRemaining,
          isActive: true,
        ),
      );
    } catch (e) {
      emit(BudgetsError(e.toString()));
    }
  }

  Future<void> _onAddBudget(AddBudget event, Emitter<BudgetsState> emit) async {
    try {
      await addBudgetUseCase(event.budget);
      emit(BudgetAdded(event.budget));

      // Reload budgets to get updated list
      add(const LoadBudgets());
    } catch (e) {
      emit(BudgetsError(e.toString()));
    }
  }

  Future<void> _onUpdateBudget(
    UpdateBudget event,
    Emitter<BudgetsState> emit,
  ) async {
    try {
      await updateBudgetUseCase(event.budget);
      emit(BudgetUpdated(event.budget));

      // Reload budgets to get updated list
      add(const LoadBudgets());
    } catch (e) {
      emit(BudgetsError(e.toString()));
    }
  }

  Future<void> _onDeleteBudget(
    DeleteBudget event,
    Emitter<BudgetsState> emit,
  ) async {
    try {
      await deleteBudgetUseCase(event.budgetId);
      emit(BudgetDeleted(event.budgetId));

      // Reload budgets to get updated list
      add(const LoadBudgets());
    } catch (e) {
      emit(BudgetsError(e.toString()));
    }
  }
}
