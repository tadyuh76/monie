import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_bloc.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_event.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_state.dart';
import 'package:monie/features/speech_to_command/presentation/widgets/command_result_widget.dart';
import 'package:monie/features/speech_to_command/presentation/widgets/speech_button_widget.dart';

class SpeechToCommandDialog extends StatelessWidget {
  const SpeechToCommandDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SpeechBloc, SpeechState>(
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
                        } else if (state is CommandParsed) {
                          instruction = 'Command recognized! Tap confirm to create transaction';
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
                          final authState = context.read<AuthBloc>().state;
                          if (authState is Authenticated) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<SpeechBloc>().add(
                                    CreateTransactionFromCommandEvent(
                                      authState.user.id,
                                    ),
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
                                  'Confirm & Create Transaction',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }
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
    );
  }
}

