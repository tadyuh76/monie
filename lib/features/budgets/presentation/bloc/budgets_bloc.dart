import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/domain/usecases/get_budgets_usecase.dart';

// Events
abstract class BudgetsEvent extends Equatable {
  const BudgetsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgets extends BudgetsEvent {
  const LoadBudgets();
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

  const BudgetsLoaded({
    required this.budgets,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.totalRemaining,
  });

  @override
  List<Object?> get props => [
    budgets,
    totalBudgeted,
    totalSpent,
    totalRemaining,
  ];
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

  BudgetsBloc({required this.getBudgetsUseCase})
    : super(const BudgetsInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
  }

  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<BudgetsState> emit,
  ) async {
    emit(const BudgetsLoading());

    try {
      final budgets = await getBudgetsUseCase();

      // Calculate totals
      final totalBudgeted = budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.totalAmount,
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
        ),
      );
    } catch (e) {
      emit(BudgetsError(e.toString()));
    }
  }
}
