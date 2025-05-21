import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:monie/core/themes/category_colors.dart';

/// Base entity class representing an account in the application.
class Account extends Equatable {
  /// Unique identifier for the account (UUID)
  final String? accountId;

  /// ID of the user who owns this account (UUID)
  final String userId;

  /// Name of the account (max 100 chars)
  final String name;

  /// Type of the account (max 30 chars)
  final String type;

  /// Current balance of the account (numeric(15,2))
  final double balance;

  /// Currency code for the account (3 chars, defaults to USD)
  final String currency;

  /// Color name for the account (e.g. 'red', 'blue')
  final String? color;

  /// Whether the account is archived
  final bool archived;

  /// Whether the account is pinned
  final bool pinned;

  /// Creates a new [Account] instance.
  const Account({
    required this.accountId,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.currency = 'USD',
    this.color,
    this.archived = false,
    this.pinned = false,
  });

  /// Creates a copy of this Account with the given fields replaced with new values.
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
    int? transactionCount,
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

  /// Gets the color of the account as a Color object
  Color getColor() {
    if (color == null) return CategoryColors.blue;
    switch (color!.toLowerCase()) {
      case 'blue':
        return CategoryColors.blue;
      case 'green':
        return CategoryColors.green;
      case 'coolGrey':
        return CategoryColors.coolGrey;
      case 'warmGrey':
        return CategoryColors.warmGrey;
      case 'teal':
        return CategoryColors.teal;
      case 'darkBlue':
        return CategoryColors.darkBlue;
      case 'red':
        return CategoryColors.red;
      case 'gold':
        return CategoryColors.gold;
      case 'orange':
        return CategoryColors.orange;
      case 'plum':
        return CategoryColors.plum;
      case 'purple':
        return CategoryColors.purple;
      case 'indigo':
        return CategoryColors.indigo;
      default:
        return CategoryColors.blue;
    }
  }

  /// Gets the number of transactions for this account
  /// This should be replaced with actual transaction count from the database
  int get transactionCount => 0;

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
}
