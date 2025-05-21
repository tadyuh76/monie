import 'package:monie/features/account/domain/entities/account.dart'; // Updated

/// A model class that represents an account in the application.
/// This class extends the base [Account] entity and provides JSON serialization capabilities.
class AccountModel extends Account {
  /// Creates a new [AccountModel] instance.
  const AccountModel({
    required super.accountId,
    required super.userId,
    required super.name,
    required super.type,
    super.balance = 0.0,
    super.currency = 'USD',
    super.color,
    super.archived = false,
    super.pinned = false,
  });

  /// Creates an [AccountModel] instance from a JSON map.
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      accountId: json['account_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      color: json['color'] as String?,
      archived: json['archived'] as bool? ?? false,
      pinned: json['pinned'] as bool? ?? false,
    );
  }

  /// Converts this [AccountModel] instance to a JSON map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'user_id': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'archived': archived,
      'pinned': pinned,
    };

    // Only include account_id if it's not null
    if (accountId != null) {
      json['account_id'] = accountId;
    }

    if (color != null) {
      json['color'] = color!;
    }

    return json;
  }

  /// Creates an [AccountModel] instance from an [Account] entity.
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
