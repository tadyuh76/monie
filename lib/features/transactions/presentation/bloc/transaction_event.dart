import 'package:equatable/equatable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionEvent {
  final String userId;

  const LoadTransactionsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadTransactionByIdEvent extends TransactionEvent {
  final String transactionId;

  const LoadTransactionByIdEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class CreateTransactionEvent extends TransactionEvent {
  final Transaction transaction;

  const CreateTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class UpdateTransactionEvent extends TransactionEvent {
  final Transaction transaction;

  const UpdateTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;

  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class LoadTransactionsByAccountEvent extends TransactionEvent {
  final String accountId;

  const LoadTransactionsByAccountEvent(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

class LoadTransactionsByBudgetEvent extends TransactionEvent {
  final String budgetId;

  const LoadTransactionsByBudgetEvent(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class FilterTransactionsEvent extends TransactionEvent {
  final String userId;
  final String type; // 'all', 'expense', 'income'
  final DateTime month;

  const FilterTransactionsEvent({
    required this.userId,
    required this.type,
    required this.month,
  });

  @override
  List<Object?> get props => [userId, type, month];
}
