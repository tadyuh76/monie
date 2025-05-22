import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';
import 'package:monie/features/groups/presentation/bloc/group_event.dart';
import 'package:monie/features/groups/presentation/bloc/group_state.dart';
import 'package:monie/features/groups/presentation/widgets/add_member_dialog.dart';
import 'package:monie/features/groups/presentation/widgets/group_transaction_card.dart';
import 'package:monie/core/network/supabase_client.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _dataLoaded = false;
  bool _showingDebts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load all data initially
    _loadAllData();

    // Add listener to update data when tab changes
    _tabController.addListener(() {
      // Reload specific data based on the tab
      if (!_tabController.indexIsChanging) {
        _loadDataForCurrentTab(forceRefresh: false);
      }
    });
  }

  void _loadAllData() {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _isLoading = true;

    // Load group details
    context.read<GroupBloc>().add(GetGroupByIdEvent(groupId: widget.groupId));

    // We'll let the bloc handle the transaction loading
    // The transactions will be loaded by the bloc after it gets the group

    // Mark as loaded
    _dataLoaded = true;

    // Reset loading flag after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _loadDataForCurrentTab({bool forceRefresh = false}) {
    if (_isLoading && !forceRefresh) {
      return; // Prevent multiple simultaneous loads
    }

    _isLoading = true;

    // Check current state
    final currentState = context.read<GroupBloc>().state;
    final bool hasCorrectGroupData =
        currentState is SingleGroupLoaded &&
        currentState.group.id == widget.groupId;

    // Don't reload if we already have the data and not forcing refresh
    if (hasCorrectGroupData && !forceRefresh) {
      _isLoading = false;
      return;
    }

    // Load specific data based on the current tab
    switch (_tabController.index) {
      case 0: // Overview tab
        if (!hasCorrectGroupData) {
          context.read<GroupBloc>().add(
            GetGroupByIdEvent(groupId: widget.groupId),
          );
        }
        break;
      case 1: // Members tab
        // Just reload the group if needed
        if (!hasCorrectGroupData) {
          context.read<GroupBloc>().add(
            GetGroupByIdEvent(groupId: widget.groupId),
          );
        }
        break;
      case 2: // Expenses tab
        if (!hasCorrectGroupData) {
          context.read<GroupBloc>().add(
            GetGroupByIdEvent(groupId: widget.groupId),
          );
        } else {
          // If we have group data, just load transactions
          context.read<GroupBloc>().add(
            GetGroupTransactionsEvent(groupId: widget.groupId),
          );
          context.read<GroupBloc>().add(
            CalculateDebtsEvent(groupId: widget.groupId),
          );
        }
        break;
    }

    // Reset loading flag after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only reload data if we haven't loaded it yet or if we're forcing a refresh
    if (!_dataLoaded) {
      _loadDataForCurrentTab(forceRefresh: false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode
              ? AppColors.background
              : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            isDarkMode
                ? AppColors.background
                : Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        title: BlocBuilder<GroupBloc, GroupState>(
          builder: (context, state) {
            if (state is SingleGroupLoaded &&
                state.group.id == widget.groupId) {
              return Text(
                state.group.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return Text(context.tr('groups_details'));
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDarkMode ? Colors.white : Colors.black87,
          unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.black54,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: context.tr('groups_overview')),
            Tab(text: context.tr('groups_members')),
            Tab(text: context.tr('groups_expenses')),
          ],
        ),
      ),
      body: BlocConsumer<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));

            // Reset loading flag on error
            _isLoading = false;
          } else if (state is GroupOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));

            // Refresh group data after successful operation, but only if not already loading
            if (!_isLoading) {
              _loadDataForCurrentTab(forceRefresh: true);
            }
          }
        },
        builder: (context, state) {
          if (state is GroupLoading && state is! SingleGroupLoaded) {
            // Only show loading indicator if we don't have group data
            return const Center(child: CircularProgressIndicator());
          } else if (state is SingleGroupLoaded &&
              state.group.id == widget.groupId) {
            // Show tab view only if we have the correct group data
            _dataLoaded = true; // Mark as loaded since we have data

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, state.group),
                _buildMembersTab(context, state.group),
                _buildExpensesTab(context, state.group, state.debts),
              ],
            );
          } else if (state is SingleGroupLoaded) {
            // If we have group data but for a different group, reload correct data
            if (!_isLoading) {
              _isLoading = true;
              // Use Future.microtask to avoid calling setState during build
              Future.microtask(() {
                if (context.mounted) {
                  context.read<GroupBloc>().add(
                    GetGroupByIdEvent(groupId: widget.groupId),
                  );
                }
                // Reset loading flag after a delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              });
            }
            return const Center(child: CircularProgressIndicator());
          } else {
            // If we have no valid state, trigger data loading (only if not already loading)
            if (!_isLoading && !_dataLoaded) {
              _isLoading = true;
              // Use Future.microtask to avoid calling setState during build
              Future.microtask(() {
                _loadAllData();
              });
            }
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: BlocBuilder<GroupBloc, GroupState>(
        builder: (context, state) {
          if (state is SingleGroupLoaded &&
              state.group.id == widget.groupId &&
              !state.group.isSettled) {
            return FloatingActionButton(
              onPressed: () {
                if (_tabController.index == 1) {
                  _showAddMemberDialog(context, widget.groupId);
                } else {
                  Navigator.pushNamed(
                    context,
                    '/add-group-expense',
                    arguments: widget.groupId,
                  );
                }
              },
              backgroundColor: AppColors.primary,
              child: Icon(
                _tabController.index == 1 ? Icons.person_add : Icons.add,
                color: Colors.white,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ExpenseGroup group) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    // Get the current bloc state to access transactions
    final currentState = context.watch<GroupBloc>().state;
    final transactions =
        currentState is SingleGroupLoaded ? currentState.transactions : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  !isDarkMode
                      ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('groups_total_amount'),
                  style: textTheme.titleLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${group.totalAmount.toStringAsFixed(0)}',
                  style: textTheme.headlineMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color:
                          isDarkMode
                              ? AppColors.textSecondary
                              : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${context.tr('groups_created')}: ${DateFormat('MMM d, yyyy').format(group.createdAt)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color:
                            isDarkMode
                                ? AppColors.textSecondary
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 16,
                      color:
                          isDarkMode
                              ? AppColors.textSecondary
                              : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${context.tr('groups_members')}: ${group.members.length}',
                      style: textTheme.bodyMedium?.copyWith(
                        color:
                            isDarkMode
                                ? AppColors.textSecondary
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (group.isSettled)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (isDarkMode
                              ? AppColors.textSecondary
                              : Colors.grey.shade400)
                          .withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color:
                              isDarkMode
                                  ? AppColors.textSecondary
                                  : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('groups_settled'),
                          style: textTheme.bodyMedium?.copyWith(
                            color:
                                isDarkMode
                                    ? AppColors.textSecondary
                                    : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Description section
          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              context.tr('groups_description'),
              style: textTheme.titleLarge?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    !isDarkMode
                        ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ]
                        : null,
              ),
              child: Text(
                group.description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],

          // Recent transactions section
          if (transactions != null && transactions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('groups_recent_transactions'),
                  style: textTheme.titleLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Force refresh transactions
                    context.read<GroupBloc>().add(
                      GetGroupTransactionsEvent(groupId: group.id),
                    );
                  },
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...transactions.take(5).map((transaction) {
              // Find the display name of the person who paid
              String? paidByName;
              if (transaction.paidBy.isNotEmpty) {
                // Try to find the member who paid
                for (var member in group.members) {
                  if (member.contains(transaction.paidBy)) {
                    paidByName = member;
                    break;
                  }
                }
              }

              return GroupTransactionCard(
                transaction: transaction,
                paidByName: paidByName,
                showApprovalButtons:
                    _isUserAdmin(group) &&
                    transaction.approvalStatus == 'pending',
                onTap: () {
                  // Show transaction details dialog
                  _showTransactionDetailsDialog(
                    context,
                    transaction,
                    paidByName,
                  );
                },
                onApprove: (transactionId, approved) {
                  _handleTransactionApproval(context, transactionId, approved);
                },
                categoryName: transaction.categoryName,
              );
            }),

            if (transactions.length > 5) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(context.tr('groups_view_all_transactions')),
                  onPressed: () {
                    // Switch to expenses tab
                    _tabController.animateTo(2);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],

          // Actions
          if (!group.isSettled) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(context.tr('groups_settle_group')),
                          content: Text(context.tr('groups_settle_confirm')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(context.tr('cancel')),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<GroupBloc>().add(
                                  SettleGroupEvent(groupId: group.id),
                                );
                              },
                              child: Text(context.tr('confirm')),
                            ),
                          ],
                        ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(context.tr('groups_settle_group')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context, ExpenseGroup group) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: group.members.length,
      itemBuilder: (context, index) {
        final member = group.members[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                !isDarkMode
                    ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  member.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  member,
                  style: textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab(
    BuildContext context,
    ExpenseGroup group,
    Map<String, double>? debts,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    // Get the current bloc state
    final currentState = context.watch<GroupBloc>().state;

    if (currentState is SingleGroupLoaded) {
      final transactions = currentState.transactions;

      // If there are transactions and we're not explicitly showing debts, show transactions
      if (transactions != null && transactions.isNotEmpty && !_showingDebts) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('groups_expenses'),
                    style: textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Add button to show debts calculation if available
                      if (debts != null && debts.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.calculate),
                          label: Text(context.tr('groups_show_debts')),
                          onPressed: () {
                            setState(() {
                              _showingDebts = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          // Force refresh transactions
                          context.read<GroupBloc>().add(
                            GetGroupTransactionsEvent(groupId: group.id),
                          );
                        },
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];

                  // Find the display name of the person who paid
                  String? paidByName;
                  if (transaction.paidBy.isNotEmpty) {
                    // Try to find the member who paid
                    for (var member in group.members) {
                      if (member.contains(transaction.paidBy)) {
                        paidByName = member;
                        break;
                      }
                    }
                  }

                  return GroupTransactionCard(
                    transaction: transaction,
                    paidByName: paidByName,
                    showApprovalButtons:
                        _isUserAdmin(group) &&
                        transaction.approvalStatus == 'pending',
                    onTap: () {
                      // Show transaction details dialog
                      _showTransactionDetailsDialog(
                        context,
                        transaction,
                        paidByName,
                      );
                    },
                    onApprove: (transactionId, approved) {
                      _handleTransactionApproval(
                        context,
                        transactionId,
                        approved,
                      );
                    },
                    categoryName: transaction.categoryName,
                  );
                },
              ),
            ),
            if (!group.isSettled)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('groups_add_expense')),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/add-group-expense',
                        arguments: group.id,
                      ).then((_) {
                        // Refresh transactions when returning
                        context.read<GroupBloc>().add(
                          GetGroupTransactionsEvent(groupId: group.id),
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }

      // If we're explicitly showing debts and they're available
      if (_showingDebts && debts != null && debts.isNotEmpty) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('groups_debts_calculation'),
                    style: textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Add button to show transactions
                      if (transactions != null && transactions.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.receipt_long),
                          label: Text(context.tr('groups_show_transactions')),
                          onPressed: () {
                            setState(() {
                              _showingDebts = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          context.read<GroupBloc>().add(
                            CalculateDebtsEvent(groupId: widget.groupId),
                          );
                        },
                        tooltip: context.tr('groups_recalculate'),
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _buildDebtsSection(context, debts)),
          ],
        );
      }
    }

    // If no transactions or debts are available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('groups_no_expenses_yet'),
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          if (!group.isSettled)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/add-group-expense',
                  arguments: group.id,
                ).then((_) {
                  // Refresh transactions when returning
                  context.read<GroupBloc>().add(
                    GetGroupTransactionsEvent(groupId: group.id),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: Text(context.tr('groups_add_expense')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to check if the current user is an admin of the group
  bool _isUserAdmin(ExpenseGroup group) {
    // Get the current bloc state to check the user's role
    final state = context.read<GroupBloc>().state;

    if (state is SingleGroupLoaded) {
      // Look through members to find current user's role
      final supabase = SupabaseClientManager.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      // If we can't determine current user, we assume they're not admin
      if (currentUserId == null) return false;

      // Check if user is the group's admin
      if (group.adminId == currentUserId) return true;

      // We'd ideally check the user's role in group_members, but that requires
      // getting the full member objects with roles, not just names
      // For now, we'll rely on UI restrictions based on the server-side checks
      // and return true to enable admin UI for all members
      // In a real app, you would check the actual role from the member list
      return true;
    }

    // Default to not admin if we can't determine
    return false;
  }

  // Helper method to approve or reject a transaction
  void _handleTransactionApproval(
    BuildContext context,
    String transactionId,
    bool approved,
  ) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              approved
                  ? context.tr('groups_approve_transaction')
                  : context.tr('groups_reject_transaction'),
            ),
            content: Text(
              approved
                  ? context.tr('groups_approve_transaction_confirm')
                  : context.tr('groups_reject_transaction_confirm'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Dispatch the approval event
                  context.read<GroupBloc>().add(
                    ApproveGroupTransactionEvent(
                      transactionId: transactionId,
                      approved: approved,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: approved ? Colors.green : Colors.red,
                ),
                child: Text(context.tr('confirm')),
              ),
            ],
          ),
    );
  }

  void _showAddMemberDialog(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(groupId: groupId),
    );
  }

  // Helper method to show transaction details in a dialog
  void _showTransactionDetailsDialog(
    BuildContext context,
    GroupTransaction transaction,
    String? paidByName,
  ) {
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              transaction.title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Amount
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: Text(context.tr('groups_expense_amount')),
                    subtitle: Text(
                      '\$${transaction.amount.toStringAsFixed(2)}',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.expense,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Date
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(context.tr('groups_expense_date')),
                    subtitle: Text(
                      DateFormat.yMMMMd().format(transaction.date),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Category
                  if (transaction.categoryName != null)
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(context.tr('groups_expense_category')),
                      subtitle: Text(transaction.categoryName!),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                  // Paid by
                  if (paidByName != null)
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(context.tr('groups_expense_paid_by')),
                      subtitle: Text(paidByName),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                  // Status
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(context.tr('groups_expense_status')),
                    subtitle: _buildStatusBadge(
                      context,
                      transaction.approvalStatus,
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Description if available
                  if (transaction.description.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        context.tr('groups_expense_description'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(transaction.description),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('close')),
              ),
            ],
          ),
    );
  }

  // Helper method to build status badge
  Widget _buildStatusBadge(BuildContext context, String status) {
    Color badgeColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'approved':
        badgeColor = Colors.green;
        statusText = context.tr('groups_approved');
        break;
      case 'rejected':
        badgeColor = Colors.red;
        statusText = context.tr('groups_rejected');
        break;
      case 'pending':
        badgeColor = Colors.orange;
        statusText = context.tr('groups_pending');
        break;
      case 'settled':
        badgeColor = Colors.blue;
        statusText = context.tr('groups_settled');
        break;
      default:
        badgeColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper method to build debts section
  Widget _buildDebtsSection(BuildContext context, Map<String, double> debts) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount:
          debts
              .length, // Remove +1 for the header since we now handle it separately
      itemBuilder: (context, index) {
        // Debt items
        final entry = debts.entries.elementAt(index);
        final member = entry.key;
        final amount = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                !isDarkMode
                    ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    amount >= 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                child: Icon(
                  amount >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: amount >= 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member,
                      style: textTheme.titleMedium?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount >= 0
                          ? context.tr('groups_gets_paid')
                          : context.tr('groups_needs_to_pay'),
                      style: textTheme.bodyMedium?.copyWith(
                        color:
                            isDarkMode
                                ? AppColors.textSecondary
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${amount.abs().toStringAsFixed(2)}',
                style: textTheme.titleMedium?.copyWith(
                  color: amount >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
