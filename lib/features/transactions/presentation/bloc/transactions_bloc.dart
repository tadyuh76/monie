import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_type_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionsEvent {
  final String userId;

  const LoadTransactions({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class FilterTransactionsByType extends TransactionsEvent {
  final String userId;
  final String? type;

  const FilterTransactionsByType({required this.userId, this.type});

  @override
  List<Object?> get props => [type];
}

class FilterTransactionsByMonth extends TransactionsEvent {
  final DateTime month;

  const FilterTransactionsByMonth(this.month);

  @override
  List<Object?> get props => [month];
}

class AddNewTransaction extends TransactionsEvent {
  final double amount;
  final String description;
  final String title;
  final DateTime date;
  final String userId;
  final String? categoryName;
  final String? categoryColor;
  final String? accountId;
  final String? budgetId;
  final bool isIncome;

  const AddNewTransaction({
    required this.amount,
    required this.description,
    required this.title,
    required this.date,
    required this.userId,
    this.categoryName,
    this.categoryColor,
    this.accountId,
    this.budgetId,
    required this.isIncome,
  });

  @override
  List<Object?> get props => [
    amount,
    description,
    title,
    date,
    userId,
    categoryName,
    categoryColor,
    accountId,
    budgetId,
    isIncome,
  ];
}

class UpdateExistingTransaction extends TransactionsEvent {
  final Transaction transaction;

  const UpdateExistingTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteExistingTransaction extends TransactionsEvent {
  final String transactionId;

  const DeleteExistingTransaction(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

// States
abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionActionInProgress extends TransactionsState {
  const TransactionActionInProgress();
}

class TransactionActionSuccess extends TransactionsState {
  final String message;

  const TransactionActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionsLoaded extends TransactionsState {
  final List<Transaction> transactions;
  final double totalExpense;
  final double totalIncome;
  final double netAmount;
  final String? activeFilter;
  final DateTime? selectedMonth;

  const TransactionsLoaded({
    required this.transactions,
    required this.totalExpense,
    required this.totalIncome,
    required this.netAmount,
    this.activeFilter,
    this.selectedMonth,
  });

  @override
  List<Object?> get props => [
    transactions,
    totalExpense,
    totalIncome,
    netAmount,
    activeFilter,
    selectedMonth,
  ];
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
@injectable
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  final GetTransactionsByTypeUseCase getTransactionsByTypeUseCase;
  final GetTransactionsByDateRangeUseCase getTransactionsByDateRangeUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  List<Transaction> _allTransactions = [];
  String? _activeFilter;
  DateTime? _selectedMonth;

  TransactionsBloc({
    required this.getTransactionsUseCase,
    required this.getTransactionsByTypeUseCase,
    required this.getTransactionsByDateRangeUseCase,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
  }) : super(const TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<FilterTransactionsByType>(_onFilterTransactionsByType);
    on<FilterTransactionsByMonth>(_onFilterTransactionsByMonth);
    on<AddNewTransaction>(_onAddNewTransaction);
    on<UpdateExistingTransaction>(_onUpdateExistingTransaction);
    on<DeleteExistingTransaction>(_onDeleteExistingTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsLoading());

    try {
      _allTransactions = await getTransactionsUseCase(event.userId);
      _emitLoadedState(emit);
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> _onFilterTransactionsByType(
    FilterTransactionsByType event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsLoading());

    try {
      if (event.type != null) {
        _activeFilter = event.type;
        _allTransactions = await getTransactionsByTypeUseCase(
          event.userId,
          event.type!,
        );
      } else {
        _activeFilter = null;
        _allTransactions = await getTransactionsUseCase(event.userId);
      }
      _emitLoadedState(emit);
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> _onFilterTransactionsByMonth(
    FilterTransactionsByMonth event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsLoading());
    _selectedMonth = event.month;

    try {
      // Create date range for the selected month
      final startDate = DateTime(event.month.year, event.month.month, 1);
      final endDate = DateTime(
        event.month.year,
        event.month.month + 1,
        0, // Last day of month
        23,
        59,
        59,
      );

      _allTransactions = await getTransactionsByDateRangeUseCase(
        startDate: startDate,
        endDate: endDate,
      );
      _emitLoadedState(emit);
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> _onAddNewTransaction(
    AddNewTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionActionInProgress());

    try {
      // Create a new transaction with a UUID
      final String transactionId = const Uuid().v4();

      final transaction = Transaction(
        transactionId: transactionId,
        amount:
            event.isIncome
                ? event.amount
                : -event.amount, // Convert to negative for expenses
        date: event.date,
        description: event.description,
        title: event.title,
        userId: event.userId,
        categoryName: event.categoryName,
        color: event.categoryColor,
        accountId: event.accountId,
        budgetId: event.budgetId,
        isRecurring: false,
      );

      // Add to repository
      await addTransactionUseCase(transaction);

      // Emit success state immediately
      emit(const TransactionActionSuccess('Transaction added successfully'));

      // Then reload transactions with fresh data from database
      _allTransactions = await getTransactionsUseCase(event.userId);
      _emitLoadedState(emit);
    } catch (e) {
      emit(TransactionsError('Failed to add transaction: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateExistingTransaction(
    UpdateExistingTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionActionInProgress());

    try {
      // Update the transaction with current timestamp
      final updatedTransaction = Transaction(
        transactionId: event.transaction.transactionId,
        amount: event.transaction.amount,
        date: event.transaction.date,
        description: event.transaction.description,
        title: event.transaction.title,
        userId: event.transaction.userId,
        categoryName: event.transaction.categoryName,
        color: event.transaction.color,
        accountId: event.transaction.accountId,
        budgetId: event.transaction.budgetId,
        isRecurring: event.transaction.isRecurring,
        receiptUrl: event.transaction.receiptUrl,
      );

      await updateTransactionUseCase(updatedTransaction);
      emit(const TransactionActionSuccess('Transaction updated successfully'));

      // Reload transactions
      add(LoadTransactions(userId: event.transaction.userId));
    } catch (e) {
      emit(TransactionsError('Failed to update transaction: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteExistingTransaction(
    DeleteExistingTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionActionInProgress());

    try {
      await deleteTransactionUseCase(event.transactionId);
      emit(const TransactionActionSuccess('Transaction deleted successfully'));

      // Reload transactions
      add(LoadTransactions(userId: event.transactionId));
    } catch (e) {
      emit(TransactionsError('Failed to delete transaction: ${e.toString()}'));
    }
  }

  void _emitLoadedState(Emitter<TransactionsState> emit) {
    List<Transaction> filteredTransactions = _allTransactions;

    // Apply additional filters if needed (already filtered by type and date in the respective events)

    // Sort by date (newest first)
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals - differentiate between income and expense based on category's is_income flag
    // Since we don't have direct access to categories, we'll determine based on amount
    // Positive amounts are income, negative are expenses
    final totalExpense = filteredTransactions
        .where((t) => t.amount < 0)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    final totalIncome = filteredTransactions
        .where((t) => t.amount >= 0)
        .fold<double>(0, (sum, t) => sum + t.amount);

    emit(
      TransactionsLoaded(
        transactions: filteredTransactions,
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        netAmount: totalIncome - totalExpense,
        activeFilter: _activeFilter,
        selectedMonth: _selectedMonth,
      ),
    );
  }
}
