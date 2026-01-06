import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_bloc.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_state.dart';

class CommandResultWidget extends StatelessWidget {
  const CommandResultWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeechBloc, SpeechState>(
      builder: (context, state) {
        if (state is SpeechResultReceived) {
          return _buildResultText(context, state.text, null);
        } else if (state is CommandParsed) {
          return _buildParsedCommand(context, state);
        } else if (state is CommandParseError) {
          return _buildError(context, state.message, state.originalText);
        } else if (state is TransactionCreated) {
          return _buildSuccess(context, state.transaction);
        } else if (state is SpeechError) {
          return _buildError(context, state.message, null);
        } else if (state is SpeechNotAvailable) {
          return _buildError(context, state.message, null);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildResultText(
    BuildContext context,
    String text,
    String? error,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error != null ? AppColors.expense : AppColors.primary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error != null ? 'Error' : 'Recognized Text',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: error != null ? AppColors.expense : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParsedCommand(BuildContext context, CommandParsed state) {
    final command = state.command;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: command.isIncome ? AppColors.income : AppColors.expense,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                command.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: command.isIncome ? AppColors.income : AppColors.expense,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                command.isIncome ? 'Income' : 'Expense',
                style: TextStyle(
                  color: command.isIncome ? AppColors.income : AppColors.expense,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(command.amount),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (command.categoryName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    command.categoryName!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (command.description != null && command.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            const Text(
              'Description',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              command.description!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, String? originalText) {
    return _buildResultText(
      context,
      originalText ?? 'Error occurred',
      message,
    );
  }

  Widget _buildSuccess(BuildContext context, transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.income.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.income,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.income,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaction Created!',
                  style: TextStyle(
                    color: AppColors.income,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount: ${Formatters.formatCurrency(transaction.amount)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

