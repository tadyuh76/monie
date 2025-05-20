import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/usecases/create_budget_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/delete_budget_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_budget_by_id_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_budgets_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/update_budget_usecase.dart';
import 'package:monie/features/transactions/presentation/bloc/budget_event.dart';
import 'package:monie/features/transactions/presentation/bloc/budget_state.dart';

@injectable
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudgetsUseCase getBudgets;
  final GetBudgetByIdUseCase getBudgetById;
  final CreateBudgetUseCase createBudget;
  final UpdateBudgetUseCase updateBudget;
  final DeleteBudgetUseCase deleteBudget;

  BudgetBloc({
    required this.getBudgets,
    required this.getBudgetById,
    required this.createBudget,
    required this.updateBudget,
    required this.deleteBudget,
  }) : super(BudgetInitial()) {
    on<LoadBudgetsEvent>(_onLoadBudgets);
    on<LoadBudgetByIdEvent>(_onLoadBudgetById);
    on<CreateBudgetEvent>(_onCreateBudget);
    on<UpdateBudgetEvent>(_onUpdateBudget);
    on<DeleteBudgetEvent>(_onDeleteBudget);
  }

  Future<void> _onLoadBudgets(
    LoadBudgetsEvent event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final budgets = await getBudgets(event.userId);
      emit(BudgetsLoaded(budgets));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onLoadBudgetById(
    LoadBudgetByIdEvent event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final budget = await getBudgetById(event.budgetId);
      if (budget != null) {
        emit(BudgetLoaded(budget));
      } else {
        emit(const BudgetError('Budget not found'));
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onCreateBudget(
    CreateBudgetEvent event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final budget = await createBudget(event.budget);
      emit(BudgetCreated(budget));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onUpdateBudget(
    UpdateBudgetEvent event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final budget = await updateBudget(event.budget);
      emit(BudgetUpdated(budget));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onDeleteBudget(
    DeleteBudgetEvent event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final success = await deleteBudget(event.budgetId);
      if (success) {
        emit(BudgetDeleted(event.budgetId));
      } else {
        emit(const BudgetError('Failed to delete budget'));
      }
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }
}
