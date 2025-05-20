import 'package:monie/features/transactions/domain/entities/account.dart';

class AccountModel extends Account {
  AccountModel({
    super.accountId,
    required super.userId,
    required super.name,
    required super.type,
    super.balance,
    super.currency,
    super.color,
    super.archived,
    super.pinned,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      accountId: json['account_id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'],
      color: json['color'],
      archived: json['archived'] ?? false,
      pinned: json['pinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'user_id': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'color': color,
      'archived': archived,
      'pinned': pinned,
    };
  }

  factory AccountModel.fromEntity(Account entity) {
    return AccountModel(
      accountId: entity.accountId,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      balance: entity.balance,
      currency: entity.currency,
      color: entity.color,
      archived: entity.archived,
      pinned: entity.pinned,
    );
  }
}
