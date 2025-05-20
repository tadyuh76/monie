import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Account extends Equatable {
  final String accountId;
  final String userId;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final String? color;
  final bool archived;
  final bool pinned;

  Account({
    String? accountId,
    required this.userId,
    required this.name,
    required this.type,
    double? balance,
    String? currency,
    this.color,
    bool? archived,
    bool? pinned,
  }) : accountId = accountId ?? const Uuid().v4(),
       balance = balance ?? 0.0,
       currency = currency ?? 'USD',
       archived = archived ?? false,
       pinned = pinned ?? false;

  @override
  List<Object?> get props => [
    accountId,
    userId,
    name,
    type,
    balance,
    currency,
    color,
    archived,
    pinned,
  ];

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      accountId: map['account_id'],
      userId: map['user_id'],
      name: map['name'],
      type: map['type'],
      balance:
          map['balance'] is int ? map['balance'].toDouble() : map['balance'],
      currency: map['currency'],
      color: map['color'],
      archived: map['archived'] ?? false,
      pinned: map['pinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
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

  Account copyWith({
    String? accountId,
    String? userId,
    String? name,
    String? type,
    double? balance,
    String? currency,
    String? color,
    bool? archived,
    bool? pinned,
  }) {
    return Account(
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      archived: archived ?? this.archived,
      pinned: pinned ?? this.pinned,
    );
  }
}
