import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/speech_to_command/domain/repositories/speech_repository.dart';

class ParseCommand {
  final SpeechRepository repository;

  ParseCommand(this.repository);

  Future<Either<Failure, SpeechCommand>> call(ParseCommandParams params) async {
    return await repository.parseCommand(params.text);
  }
}

class ParseCommandParams extends Equatable {
  final String text;

  const ParseCommandParams({required this.text});

  @override
  List<Object?> get props => [text];
}

