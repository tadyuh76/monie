import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/speech_to_command/domain/repositories/speech_repository.dart';

class RecognizeSpeech {
  final SpeechRepository repository;

  RecognizeSpeech(this.repository);

  Future<Either<Failure, Stream<String>>> call(RecognizeSpeechParams params) async {
    // Check if speech recognition is available
    final availabilityResult = await repository.isAvailable();
    return availabilityResult.fold(
      (failure) => Left(failure),
      (isAvailable) async {
        if (!isAvailable) {
          return Left(SpeechNotAvailableFailure());
        }

        // Initialize if needed
        final initResult = await repository.initialize();
        return initResult.fold(
          (failure) => Left(failure),
          (_) async {
            // Start listening
            return await repository.startListening();
          },
        );
      },
    );
  }
}

class RecognizeSpeechParams extends Equatable {
  @override
  List<Object?> get props => [];
}

