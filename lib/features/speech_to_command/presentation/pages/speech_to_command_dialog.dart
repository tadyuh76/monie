import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_bloc.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_event.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_state.dart';
import 'package:monie/features/speech_to_command/presentation/widgets/command_result_widget.dart';
import 'package:monie/features/speech_to_command/presentation/widgets/speech_button_widget.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/widgets/add_transaction_form.dart';

/// Helper class for pre-filling transaction form from voice command
class _PreFillTransaction {
  final String? title;
  final double amount;
  final String? description;
  final DateTime date;
  final String? categoryName;
  final bool isRecurring;
  final String? accountId;

  _PreFillTransaction({
    this.title,
    required this.amount,
    this.description,
    required this.date,
    this.categoryName,
    this.isRecurring = false,
    this.accountId,
  });
}

void _openTransactionFormWithCommand(BuildContext context, SpeechCommand command) {
  // Get required blocs from the parent context before dialog was closed
  final transactionBloc = context.read<TransactionBloc>();
  final accountBloc = context.read<AccountBloc>();
  final budgetsBloc = context.read<BudgetsBloc>();
  final authBloc = context.read<AuthBloc>();

  // Create pre-fill transaction object
  final preFillTransaction = _PreFillTransaction(
    title: command.description,
    amount: command.isIncome ? command.amount : -command.amount,
    description: command.description,
    date: command.date ?? DateTime.now(),
    categoryName: command.categoryName,
    isRecurring: false,
    accountId: command.accountId,
  );

  // Use a post-frame callback to ensure the dialog is fully closed
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: transactionBloc),
            BlocProvider.value(value: accountBloc),
            BlocProvider.value(value: budgetsBloc),
            BlocProvider.value(value: authBloc),
          ],
          child: AddTransactionForm(
            transaction: preFillTransaction,
            onSubmit: (Map<String, dynamic> transactionData) {
              final authState = authBloc.state;
              if (authState is Authenticated) {
                final newTransaction = Transaction(
                  userId: authState.user.id,
                  title: transactionData['title'],
                  amount: transactionData['amount'],
                  description: transactionData['description'] ?? '',
                  date: DateTime.parse(transactionData['date']),
                  categoryName: transactionData['category_name'],
                  color: transactionData['category_color'],
                  accountId: transactionData['account_id'],
                  budgetId: transactionData['budget_id'],
                );
                transactionBloc.add(CreateTransactionEvent(newTransaction));
              }
            },
          ),
        );
      },
    );
  });
}

class SpeechToCommandDialog extends StatelessWidget {
  const SpeechToCommandDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Dialog is being closed (via back button or other means), cancel listening
          context.read<SpeechBloc>().add(const CancelListeningEvent());
        }
      },
      child: BlocListener<SpeechBloc, SpeechState>(
        listener: (context, state) {
          if (state is TransactionCreated) {
            // Close dialog after a short delay
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                Navigator.of(context).pop();
                // Reset state
                context.read<SpeechBloc>().add(const ResetSpeechStateEvent());
              }
            });
          } else if (state is CommandReadyForForm) {
            // Close dialog and open transaction form with pre-filled data
            Navigator.of(context).pop();
            context.read<SpeechBloc>().add(const ResetSpeechStateEvent());
            _openTransactionFormWithCommand(context, state.command);
          }
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mic,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Voice Transaction',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          context.read<SpeechBloc>().add(const CancelListeningEvent());
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Instructions
                      BlocBuilder<SpeechBloc, SpeechState>(
                        builder: (context, state) {
                          String instruction = 'Tap the microphone to start';
                          if (state is SpeechListening) {
                            instruction = 'Listening... Speak your command';
                          } else if (state is CommandParsing) {
                            instruction = 'Processing with AI...';
                          } else if (state is CommandParsed) {
                            instruction = 'Command recognized! Review and edit in form';
                          } else if (state is CreatingTransaction) {
                            instruction = 'Creating transaction...';
                          }

                          return Text(
                            instruction,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Speech Button
                      const SpeechButtonWidget(),

                      const SizedBox(height: 30),

                      // Command Result
                      const CommandResultWidget(),

                      const SizedBox(height: 20),

                      // Action Buttons
                      BlocBuilder<SpeechBloc, SpeechState>(
                        builder: (context, state) {
                          if (state is CommandParsed) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<SpeechBloc>().add(
                                    const OpenTransactionFormEvent(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Review & Edit in Form',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 10),

                      // Cancel/Reset Button
                      BlocBuilder<SpeechBloc, SpeechState>(
                        builder: (context, state) {
                          if (state is! SpeechInitial && state is! SpeechCheckingAvailability) {
                            return TextButton(
                              onPressed: () {
                                context.read<SpeechBloc>().add(const ResetSpeechStateEvent());
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

