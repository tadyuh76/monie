import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountRepositorySupabaseImpl implements AccountRepository {
  final supabase = Supabase.instance.client;

  @override
  Future<List<Account>> getAccounts() async {
    final response = await supabase.from('accounts').select();
    return (response as List)
        .map((json) => Account(
              id: json['id'].toString(),
              name: json['name'],
              type: json['type'],
              balance: (json['balance'] as num).toDouble(),
              currency: json['currency'],
              transactionCount: json['transaction_count'] ?? 0,
            ))
        .toList();
  }

  @override
  Future<Account> getAccountById(String id) async {
    final response = await supabase.from('accounts').select().eq('id', id).single();
    return Account(
      id: response['id'].toString(),
      name: response['name'],
      type: response['type'],
      balance: (response['balance'] as num).toDouble(),
      currency: response['currency'],
      transactionCount: response['transaction_count'] ?? 0,
    );
  }

  @override
  Future<void> addAccount(Account account) async {
    await supabase.from('accounts').insert({
      'id': account.id,
      'name': account.name,
      'type': account.type,
      'balance': account.balance,
      'currency': account.currency,
      'transaction_count': account.transactionCount,
    });
  }

  @override
  Future<void> updateAccount(Account account) async {
    await supabase.from('accounts').update({
      'name': account.name,
      'type': account.type,
      'balance': account.balance,
      'currency': account.currency,
      'transaction_count': account.transactionCount,
    }).eq('id', account.id);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await supabase.from('accounts').delete().eq('id', id);
  }
} 