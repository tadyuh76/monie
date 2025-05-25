import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';
import 'package:monie/features/notifications/domain/usecases/create_budget_notification.dart';
import 'package:monie/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transaction_by_id_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_account_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_budget_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';

@injectable
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsUseCase getTransactions;
  final GetTransactionByIdUseCase getTransactionById;
  final AddTransactionUseCase createTransaction;
  final UpdateTransactionUseCase updateTransaction;
  final DeleteTransactionUseCase deleteTransaction;
  final GetTransactionsByAccountUseCase getTransactionsByAccount;
  final GetTransactionsByBudgetUseCase getTransactionsByBudget;
  final CreateBudgetNotification createBudgetNotification;
  final BudgetRepository budgetRepository;

  TransactionBloc({
    required this.getTransactions,
    required this.getTransactionById,
    required this.createTransaction,
    required this.updateTransaction,
    required this.deleteTransaction,
    required this.getTransactionsByAccount,
    required this.getTransactionsByBudget,
    required this.createBudgetNotification,
    required this.budgetRepository,
  }) : super(TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<LoadTransactionByIdEvent>(_onLoadTransactionById);
    on<CreateTransactionEvent>(_onCreateTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<LoadTransactionsByAccountEvent>(_onLoadTransactionsByAccount);
    on<LoadTransactionsByBudgetEvent>(_onLoadTransactionsByBudget);
    on<FilterTransactionsEvent>(_onFilterTransactions);
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await getTransactions(event.userId);
      emit(TransactionsLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadTransactionById(
    LoadTransactionByIdEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transaction = await getTransactionById(event.transactionId);
      if (transaction != null) {
        emit(TransactionLoaded(transaction));
      } else {
        emit(const TransactionError('Transaction not found'));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onCreateTransaction(
    CreateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transaction = await createTransaction(event.transaction);

      // Check for budget notifications if this transaction affects a budget
      await _checkBudgetNotifications(event.transaction);

      emit(TransactionCreated(transaction));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transaction = await updateTransaction(event.transaction);

      // Check for budget notifications if this transaction affects a budget
      await _checkBudgetNotifications(event.transaction);

      emit(TransactionUpdated(transaction));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final success = await deleteTransaction(event.transactionId);
      if (success) {
        emit(TransactionDeleted(event.transactionId));
      } else {
        emit(const TransactionError('Failed to delete transaction'));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadTransactionsByAccount(
    LoadTransactionsByAccountEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await getTransactionsByAccount(event.accountId);
      emit(TransactionsLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadTransactionsByBudget(
    LoadTransactionsByBudgetEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await getTransactionsByBudget(event.budgetId);
      emit(TransactionsLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onFilterTransactions(
    FilterTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final allTransactions = await getTransactions(event.userId);
      // Filter by month
      final filteredByMonth = allTransactions.where(
        (t) =>
            t.date.year == event.month.year &&
            t.date.month == event.month.month,
      );
      // Filter by type
      final filtered =
          event.type == 'all'
              ? filteredByMonth
              : filteredByMonth.where(
                (t) =>
                    (event.type == 'expense' && t.amount < 0) ||
                    (event.type == 'income' && t.amount >= 0),
              );
      emit(TransactionsLoaded(filtered.toList()));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  // Helper method to check if budget notifications should be sent
  Future<void> _checkBudgetNotifications(transaction) async {
    try {
      // Only check if the transaction affects a budget
      if (transaction.budgetId == null || transaction.budgetId!.isEmpty) {
        return;
      }

      // Get the budget details
      final budget = await budgetRepository.getBudgetById(
        transaction.budgetId!,
      );

      // For expense budgets, only consider negative amounts (expenses)
      // For income budgets, only consider positive amounts (income)
      final isExpenseBudget = !budget.isSaving;
      final isIncomeBudget = budget.isSaving;

      if (isExpenseBudget && transaction.amount >= 0) {
        return; // Skip positive amounts for expense budgets
      }
      if (isIncomeBudget && transaction.amount < 0) {
        return; // Skip negative amounts for income budgets
      }

      // Calculate current spending/earning for this budget
      final spentAmount = budget.spentAmount;
      final percentage = spentAmount / budget.amount;

      // Check if we need to send a notification at 50%, 80%, or 100% thresholds
      if (percentage >= 0.5) {
        await createBudgetNotification(
          userId: transaction.userId,
          budgetName: budget.name,
          amount: budget.amount,
          spentAmount: spentAmount,
          percentage: percentage * 100,
        );
      }
    } catch (e) {
      // Don't fail the transaction if budget notification fails
      // Just log the error silently
    }
  }
}
