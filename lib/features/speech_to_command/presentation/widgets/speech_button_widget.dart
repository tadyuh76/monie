import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_bloc.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_event.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_state.dart';

class SpeechButtonWidget extends StatelessWidget {
  const SpeechButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeechBloc, SpeechState>(
      builder: (context, state) {
        final isListening = state is SpeechListening;
        final isLoading = state is SpeechCheckingAvailability || 
                         state is CommandParsing || 
                         state is CreatingTransaction;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  if (isListening) {
                    context.read<SpeechBloc>().add(const StopListeningEvent());
                  } else {
                    context.read<SpeechBloc>().add(const StartListeningEvent());
                  }
                },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? AppColors.expense
                  : AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: (isListening ? AppColors.expense : AppColors.primary)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: isListening ? 10 : 5,
                ),
              ],
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    size: 40,
                    color: Colors.white,
                  ),
          ),
        );
      },
    );
  }
}

