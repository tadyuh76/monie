import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getwidget/components/checkbox_list_tile/gf_checkbox_list_tile.dart';
import 'package:getwidget/types/gf_checkbox_type.dart';
import 'package:monie/core/themes/app_colors.dart';

import '../../../../core/model/sort.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../home/domain/entities/account.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../transactions/domain/entities/transaction.dart';
import 'add_account_page.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';

class EditAccountsPage extends StatefulWidget {
  final List<Account> accounts;
  final List<Transaction> transactions;

  const EditAccountsPage({
    super.key,
    required this.accounts,
    required this.transactions,
  });

  @override
  State<EditAccountsPage> createState() => _EditAccountsPageState();
}

class _EditAccountsPageState extends State<EditAccountsPage> {
  late List<Account> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = List.from(widget.accounts);
    _selectedType = items.map((item) => item.type).toList();
  }

  List<Account> get accounts => _accounts;
  set accounts(List<Account> newAccounts) {
    setState(() {
      _accounts = newAccounts;
    });
  }

  final items = [
    Sort(name: 'Cash', type: 'cash'),
    Sort(name: 'Bank', type: 'bank'),
    Sort(name: 'Savings', type: 'savings'),
    Sort(name: 'Credit', type: 'credit'),
    Sort(name: 'Debit', type: 'debit'),
    Sort(name: 'Investment', type: 'investment'),
  ];
  List _selectedType = [];
  bool showArchived = false;

  Future<bool> _deleteAccount(int index, {Function(int)? remove}) async {
    final name = accounts[index].name;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Delete Account',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Are you sure you want to delete "$name"?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      if (remove != null) {
        remove(index).call();
      }
      return true;
    }
    return false;
  }

  void _archiveAccount(
    int index, {
    Function(Account account)? archiveAccount,
  }) async {
    final name = accounts[index].name;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Archive Account',
              style: TextStyle(color: AppColors.primary),
            ),
            content: Text(
              'Archive "$name"?',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Archive',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      setState(() {
        final updatedAccount = accounts[index].copyWith(archived: true);
        accounts[index] = updatedAccount;
        if (archiveAccount != null) {
          archiveAccount(updatedAccount).call();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account archived successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _unarchiveAccount(
    int index, {
    Function(Account account)? unarchiveAccount,
  }) {
    setState(() {
      final updatedAccount = accounts[index].copyWith(archived: false);
      accounts[index] = updatedAccount;
      if (unarchiveAccount != null) {
        unarchiveAccount(updatedAccount).call();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account unarchived successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _reconcileAccount(
    int index, {
    Function(Account account1, Account account2)? reconcileAccount,
  }) async {
    final acc = accounts[index];
    final otherAccounts =
        accounts
            .where((a) => a.accountId != acc.accountId && !a.archived)
            .toList();
    String? selectedId;
    final confirm = await showDialog<String>(
      context: context,
      builder: (context) {
        String? tempSelectedId = selectedId;
        return StatefulBuilder(
          builder:
              (context, setModalState) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text(
                  'Reconcile Account',
                  style: TextStyle(color: AppColors.primary),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select account to transfer balance to:',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[900],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      value: tempSelectedId,
                      items:
                          otherAccounts
                              .map<DropdownMenuItem<String>>(
                                (a) => DropdownMenuItem<String>(
                                  value: a.accountId,
                                  child: Text(
                                    a.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        setModalState(() {
                          tempSelectedId = v;
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(tempSelectedId),
                    child: const Text(
                      'Reconcile',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
        );
      },
    );
    if (confirm != null) {
      final destIndex = accounts.indexWhere((a) => a.accountId == confirm);
      setState(() {
        final destAccount = accounts[destIndex].copyWith(
          balance: accounts[destIndex].balance + acc.balance,
        );
        final sourceAccount = acc.copyWith(balance: 0);
        accounts[destIndex] = destAccount;
        accounts[index] = sourceAccount;
        if (reconcileAccount != null) {
          reconcileAccount(destAccount, sourceAccount).call();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconciled successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _editAccount(int index) async {
    if (!mounted) return;
    final acc = accounts[index];
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAccountPage(account: acc, isEdit: true),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        accounts[index] = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account updated successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = accounts.removeAt(oldIndex);
      accounts.insert(newIndex, item);
    });
  }

  List<Account> get filteredAccounts {
    return accounts
        .where(
          (acc) =>
              (_selectedType.contains(acc.type)) &&
              (acc.archived == showArchived),
        )
        .toList();
  }

  void _showFilterDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        bool tempShowArchived = showArchived;
        return StatefulBuilder(
          builder:
              (context, setModalState) => AlertDialog(
                backgroundColor: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  'Filter Accounts',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: List.generate(
                          items.length,
                          (index) => Container(
                            margin: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color:
                                  _selectedType.contains(items[index].type)
                                      ? AppColors.primary.withAlpha(20)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: GFCheckboxListTile(
                              padding: EdgeInsets.zero,
                              value: _selectedType.contains(items[index].type),
                              onChanged: (bool selected) {
                                if (selected == true) {
                                  setModalState(() {
                                    {
                                      _selectedType.add(items[index].type);
                                    }
                                  });
                                } else {
                                  setModalState(() {
                                    {
                                      _selectedType.remove(items[index].type);
                                    }
                                  });
                                }
                              },
                              title: Text(
                                items[index].name ?? '',
                                style: TextStyle(
                                  color:
                                      _selectedType.contains(items[index].type)
                                          ? AppColors.primary
                                          : Colors.white,
                                ),
                              ),
                              margin: EdgeInsets.zero,
                              type: GFCheckboxType.basic,
                              activeBgColor: AppColors.primary,
                              activeBorderColor: AppColors.primary,
                              inactiveBorderColor: AppColors.primary,
                              customBgColor:
                                  _selectedType.contains(items[index])
                                      ? AppColors.primary.withAlpha(50)
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: tempShowArchived,
                        onChanged: (v) {
                          setModalState(() => tempShowArchived = v ?? false);
                        },
                        title: Text(
                          'Show Archived',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showArchived = tempShowArchived;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is DeleteAccountState) {
          accounts = state.accounts;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<HomeBloc>().add(LoadHomeData(authState.user.id));
            context.read<AccountBloc>().add(
              GetAccountsEvent(userId: authState.user.id),
            );
          }
        }

        if (state is UpdateAccountState) {
          accounts = state.accounts;
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<AccountBloc>().add(
              GetAccountsEvent(userId: authState.user.id),
            );
            context.read<HomeBloc>().add(LoadHomeData(authState.user.id));
          }
        }

        if (state is GetAccountsState) {
          accounts = state.accounts;
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<AccountBloc>().add(
              GetAccountsEvent(userId: authState.user.id),
            );
            context.read<HomeBloc>().add(LoadHomeData(authState.user.id));
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            return BlocBuilder<AccountBloc, AccountState>(
              builder: (context, state) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    title: Text(
                      'Edit Accounts',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.black,
                    actions: [
                      IconButton(
                        icon: Icon(Icons.filter_list, color: AppColors.primary),
                        onPressed: _showFilterDialog,
                      ),
                    ],
                  ),
                  body:
                      filteredAccounts.isEmpty
                          ? Container(
                            height: double.infinity,
                            width: double.infinity,
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                'Not found account!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                          : ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: filteredAccounts.length,
                            padding: EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 10,
                            ),
                            onReorder: _reorder,
                            itemBuilder: (context, index) {
                              final acc = filteredAccounts[index];
                              return Dismissible(
                                key: ValueKey(acc.accountId),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                direction: DismissDirection.endToStart,
                                confirmDismiss:
                                    (_) => _deleteAccount(
                                      index,
                                      remove: (int index) {
                                        context.read<AccountBloc>().add(
                                          DeleteAccountEvent(
                                            account: accounts[index],
                                          ),
                                        );
                                      },
                                    ),
                                child: GestureDetector(
                                  onTap: () => _editAccount(index),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(35.0),
                                    child: Container(
                                      color: Colors.grey[900],
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      height: 100,
                                      width: double.infinity,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 2.0,
                                            height: double.infinity,
                                            color: acc.getColor(),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.drag_handle,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  acc.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  '${acc.type} • ${acc.balance} ${acc.currency} • ${acc.transactionCount} transactions',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            color: Colors.grey[900],
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: AppColors.primary,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editAccount(index);
                                              }
                                              if (value == 'archive') {
                                                _archiveAccount(
                                                  index,
                                                  archiveAccount: (
                                                    Account account,
                                                  ) {
                                                    context
                                                        .read<AccountBloc>()
                                                        .add(
                                                          UpdateAccountEvent(
                                                            account: account,
                                                          ),
                                                        );
                                                  },
                                                );
                                              }
                                              if (value == 'unarchive') {
                                                _unarchiveAccount(
                                                  index,
                                                  unarchiveAccount: (
                                                    Account account,
                                                  ) {
                                                    context
                                                        .read<AccountBloc>()
                                                        .add(
                                                          UpdateAccountEvent(
                                                            account: account,
                                                          ),
                                                        );
                                                  },
                                                );
                                              }
                                              if (value == 'reconcile') {
                                                _reconcileAccount(
                                                  index,
                                                  reconcileAccount: (
                                                    Account account1,
                                                    Account account2,
                                                  ) {
                                                    context
                                                        .read<AccountBloc>()
                                                        .add(
                                                          UpdateAccountEvent(
                                                            account: account1,
                                                          ),
                                                        );
                                                    context
                                                        .read<AccountBloc>()
                                                        .add(
                                                          UpdateAccountEvent(
                                                            account: account2,
                                                          ),
                                                        );
                                                  },
                                                );
                                              }
                                              if (value == 'delete') {
                                                _deleteAccount(
                                                  index,
                                                  remove: (int index) {
                                                    context
                                                        .read<AccountBloc>()
                                                        .add(
                                                          DeleteAccountEvent(
                                                            account:
                                                                accounts[index],
                                                          ),
                                                        );
                                                  },
                                                );
                                              }
                                            },
                                            itemBuilder:
                                                (context) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: ListTile(
                                                      leading: Icon(Icons.edit),
                                                      title: Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (acc.archived == false)
                                                    const PopupMenuItem(
                                                      value: 'archive',
                                                      child: ListTile(
                                                        leading: Icon(
                                                          Icons.archive,
                                                        ),
                                                        title: Text(
                                                          'Archive',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (acc.archived == true)
                                                    const PopupMenuItem(
                                                      value: 'unarchive',
                                                      child: ListTile(
                                                        leading: Icon(
                                                          Icons.unarchive,
                                                        ),
                                                        title: Text(
                                                          'Unarchive',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  const PopupMenuItem(
                                                    value: 'reconcile',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.call_merge,
                                                      ),
                                                      title: Text(
                                                        'Reconcile',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.delete,
                                                      ),
                                                      title: Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  floatingActionButton: FloatingActionButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddAccountPage(account: null),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          accounts.add(result);
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account added successfully!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.add, color: Colors.black87),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
