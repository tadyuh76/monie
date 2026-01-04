import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

class CreateTransactionFromCommand {
  final TransactionRepository transactionRepository;

  CreateTransactionFromCommand(this.transactionRepository);

  Future<Either<Failure, Transaction>> call(
    CreateTransactionFromCommandParams params,
  ) async {
    final command = params.command;
    final userId = params.userId;

    if (!command.isValid) {
      return Left(InvalidCommandFailure('Invalid command: amount must be greater than 0'));
    }

    // Create transaction from command
    final transaction = Transaction(
      userId: userId,
      amount: command.amount,
      title: command.description ?? 
          (command.isIncome ? 'Income' : 'Expense'),
      description: command.description,
      categoryName: command.categoryName,
      accountId: command.accountId,
      date: DateTime.now(),
    );

    try {
      final createdTransaction = await transactionRepository.createTransaction(transaction);
      return Right(createdTransaction);
    } catch (e) {
      return Left(ServerFailure('Failed to create transaction: $e'));
    }
  }
}

class CreateTransactionFromCommandParams extends Equatable {
  final SpeechCommand command;
  final String userId;

  const CreateTransactionFromCommandParams({
    required this.command,
    required this.userId,
  });

  @override
  List<Object?> get props => [command, userId];
}

