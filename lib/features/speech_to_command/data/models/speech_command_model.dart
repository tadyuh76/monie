import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';

/// Model for SpeechCommand (same as entity in this case)
class SpeechCommandModel extends SpeechCommand {
  const SpeechCommandModel({
    required super.amount,
    super.categoryName,
    super.description,
    super.isIncome,
    super.accountId,
  });

  factory SpeechCommandModel.fromEntity(SpeechCommand entity) {
    return SpeechCommandModel(
      amount: entity.amount,
      categoryName: entity.categoryName,
      description: entity.description,
      isIncome: entity.isIncome,
      accountId: entity.accountId,
    );
  }
}

