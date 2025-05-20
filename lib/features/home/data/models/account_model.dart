import 'package:monie/features/home/domain/entities/account.dart';

class AccountModel extends Account {
  AccountModel({
    super.id,
    super.user_id,
    super.name,
    super.type,
    required super.balance,
    super.currency,
    super.archived,
    super.color,
    super.pinned,
    super.transactionCount,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      user_id: json['user_id'],
      name: json['name'],
      type: json['type'],
      balance: json['balance'].toDouble(),
      currency: json['currency'],
      archived: json['archived'],
      color: json['color'],
      pinned: json['pinned'],
      transactionCount: json['transactionCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': user_id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'archived': archived,
      'color': color,
      'pinned': pinned,
      'transactionCount': transactionCount,
    };
  }

  factory AccountModel.fromEntity(Account entity) {
    return AccountModel(
      id: entity.id,
      user_id: entity.user_id,
      name: entity.name,
      type: entity.type,
      balance: entity.balance,
      currency: entity.currency,
      archived: entity.archived,
      color: entity.color,
      pinned: entity.pinned,
      transactionCount: entity.transactionCount,
    );
  }
}
