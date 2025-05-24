import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';
import 'package:monie/features/groups/presentation/bloc/group_event.dart';
import 'package:monie/features/groups/presentation/bloc/group_state.dart';
import 'package:monie/features/groups/presentation/widgets/add_member_dialog.dart';
import 'package:monie/features/groups/presentation/widgets/group_transaction_card.dart';

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
  String?
  _lastShownMessage; // Track the last shown message to prevent duplicates

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

    setState(() {
      _isLoading = true;
    });

    // Load group details
    context.read<GroupBloc>().add(GetGroupByIdEvent(groupId: widget.groupId));

    // We'll let the bloc handle the transaction loading
    // The transactions will be loaded by the bloc after it gets the group

    // Mark as loaded
    _dataLoaded = true;

    // The loading flag will be reset in the listener when data arrives
  }

  void _loadDataForCurrentTab({bool forceRefresh = false}) {
    if (_isLoading && !forceRefresh) {
      return; // Prevent multiple simultaneous loads
    }

    setState(() {
      _isLoading = true;
    });

    // Check current state
    final currentState = context.read<GroupBloc>().state;
    final bool hasCorrectGroupData =
        currentState is SingleGroupLoaded &&
        currentState.group.id == widget.groupId;

    // Load specific data based on the current tab
    switch (_tabController.index) {
      case 0: // Overview tab
        if (!hasCorrectGroupData) {
          context.read<GroupBloc>().add(
            GetGroupByIdEvent(groupId: widget.groupId),
          );
        } else {
          // Load transactions for the overview tab
          context.read<GroupBloc>().add(
            GetGroupTransactionsEvent(groupId: widget.groupId),
          );
        }
        break;
      case 1: // Members tab
        // Load group data if needed
        if (!hasCorrectGroupData) {
          context.read<GroupBloc>().add(
            GetGroupByIdEvent(groupId: widget.groupId),
          );
        }
        // No need to load separate members data since we use group.members
        break;
      case 2: // Debts tab
        // Just reload the group if needed
        if (!hasCorrectGroupData) {
          context.read<GroupBloc>().add(
            GetGroupByIdEvent(groupId: widget.groupId),
          );
        }
        break;
    }

    // The loading flag will be reset in the listener when data arrives
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
            Tab(text: context.tr('groups_debts')),
          ],
        ),
      ),
      body: BlocConsumer<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupError) {
            if (_lastShownMessage != state.message) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              _lastShownMessage = state.message;

              // Reset after 3 seconds to allow the same message to be shown again if needed
              Timer(Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _lastShownMessage = null;
                  });
                }
              });
            }

            // Reset loading flag on error
            setState(() {
              _isLoading = false;
            });
          } else if (state is GroupOperationSuccess) {
            // Only show snackbars for operations relevant to group details
            if (state.message.contains('Member added') ||
                state.message.contains('Member removed') ||
                state.message.contains('Member role updated') ||
                state.message.contains('Group settled') ||
                state.message.contains('Transaction approved') ||
                state.message.contains('Transaction rejected')) {
              if (_lastShownMessage != state.message) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
                _lastShownMessage = state.message;

                // Reset after 3 seconds to allow the same message to be shown again if needed
                Timer(Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() {
                      _lastShownMessage = null;
                    });
                  }
                });
              }
            }

            // Reset loading flag after successful operation
            setState(() {
              _isLoading = false;
            });

            // The bloc will automatically refresh data, so we don't need to manually trigger it here
          } else if (state is SingleGroupLoaded &&
              state.group.id == widget.groupId) {
            // Reset loading flag when we receive updated group data
            setState(() {
              _isLoading = false;
              _dataLoaded = true;
            });
          } else if (state is GroupMembersLoaded) {
            // Reset loading flag when we receive members data
            setState(() {
              _isLoading = false;
            });
          }
        },
        builder: (context, state) {
          if (state is GroupLoading && !_dataLoaded) {
            // Only show loading indicator if we don't have any data yet
            return const Center(child: CircularProgressIndicator());
          } else if (state is SingleGroupLoaded &&
              state.group.id == widget.groupId) {
            // Show tab view when we have the correct group data
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, state.group),
                _buildMembersTab(context, state.group),
                _buildDebtsTab(context, state.group),
              ],
            );
          } else if (state is SingleGroupLoaded) {
            // If we have group data but for a different group, reload correct data
            if (!_isLoading) {
              setState(() {
                _isLoading = true;
              });
              // Use Future.microtask to avoid calling setState during build
              Future.microtask(() {
                if (context.mounted) {
                  context.read<GroupBloc>().add(
                    GetGroupByIdEvent(groupId: widget.groupId),
                  );
                }
              });
            }
            return const Center(child: CircularProgressIndicator());
          } else {
            // If we have no valid state, trigger data loading (only if not already loading)
            if (!_isLoading && !_dataLoaded) {
              setState(() {
                _isLoading = true;
              });
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
                } else if (_tabController.index == 0 ||
                    _tabController.index == 2) {
                  // Add expense for both overview and debts tabs
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

    return BlocBuilder<GroupBloc, GroupState>(
      buildWhen: (previous, current) {
        // Only rebuild if we have new transaction data for this group
        if (current is SingleGroupLoaded &&
            current.group.id == widget.groupId) {
          if (previous is SingleGroupLoaded &&
              previous.group.id == widget.groupId) {
            // Check if transactions actually changed
            return previous.transactions != current.transactions ||
                previous.group.totalAmount != current.group.totalAmount ||
                previous.group.isSettled != current.group.isSettled;
          }
          return true; // First time loading this group
        }
        return false; // Don't rebuild for other states
      },
      builder: (context, state) {
        final transactions =
            state is SingleGroupLoaded && state.group.id == widget.groupId
                ? state.transactions
                : null;

        return _buildOverviewContent(
          context,
          group,
          transactions,
          isDarkMode,
          textTheme,
        );
      },
    );
  }

  Widget _buildOverviewContent(
    BuildContext context,
    ExpenseGroup group,
    List<dynamic>? transactions,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    // Group transactions by date
    final Map<String, List<dynamic>> groupedTransactions = {};

    if (transactions != null && transactions.isNotEmpty) {
      // Sort transactions by date (newest first)
      final sortedTransactions = List.from(transactions);
      sortedTransactions.sort((a, b) => b.date.compareTo(a.date));

      // Group by date
      for (var transaction in sortedTransactions) {
        final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
        if (!groupedTransactions.containsKey(dateKey)) {
          groupedTransactions[dateKey] = [];
        }
        groupedTransactions[dateKey]!.add(transaction);
      }
    }

    // Build the children widgets list
    List<Widget> children = [
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
            // Actions section
            if (!group.isSettled) const SizedBox(height: 24),

            if (!group.isSettled)
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
                                child: Text(context.tr('common_cancel')),
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
    ];

    // Description section
    if (group.description != null && group.description!.isNotEmpty) {
      children.addAll([
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
      ]);
    }

    // Transactions section
    if (transactions != null) {
      children.add(const SizedBox(height: 24));
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('groups_transactions'),
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
      );

      if (transactions.isEmpty) {
        // No transactions yet
        children.addAll([
          const SizedBox(height: 16),
          Center(
            child: Column(
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
              ],
            ),
          ),
        ]);
      } else {
        // Display transactions grouped by date
        for (final entry in groupedTransactions.entries) {
          final dateStr = entry.key;
          final dateTransactions = entry.value;

          // Format the date for display
          final date = DateTime.parse(dateStr);
          final formattedDate = DateFormat.yMMMMd().format(date);

          // Add date header
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                formattedDate,
                style: textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );

          // Add transactions for this date
          for (final transaction in dateTransactions) {
            // Find the display name of the person who paid
            String? paidByName;

            // Check if transaction has user display name from the join
            if (transaction.paidBy.isNotEmpty) {
              // First try to get the name from the transaction's user data
              // The data source joins with users table to get display_name
              if (transaction is Map<String, dynamic> &&
                  transaction['users'] != null &&
                  transaction['users']['display_name'] != null) {
                paidByName = transaction['users']['display_name'];
              } else {
                // Use the helper method to get the display name
                paidByName = _getDisplayNameForUserId(
                  transaction.paidBy,
                  group,
                );
              }
            }

            children.add(
              GroupTransactionCard(
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
              ),
            );
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context, ExpenseGroup group) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    // Use the group members data directly instead of requiring a separate state
    // Parse the members from the group.members list
    final List<Map<String, String>> parsedMembers = [];

    for (var member in group.members) {
      // Extract user ID from member string if it contains it (format: "Name (userId)")
      final match = RegExp(r'^(.+?)\s*\(([^)]+)\)$').firstMatch(member);
      if (match != null) {
        final displayName = match.group(1)?.trim() ?? member;
        final userId = match.group(2);
        if (userId != null) {
          parsedMembers.add({
            'displayName': displayName,
            'userId': userId,
            'role': userId == group.adminId ? 'admin' : 'member',
          });
        }
      } else {
        // If no ID in parentheses, use the member string as both ID and name
        parsedMembers.add({
          'displayName': member,
          'userId': member,
          'role': member == group.adminId ? 'admin' : 'member',
        });
      }
    }

    final isCurrentUserAdmin = _isUserAdmin(group);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parsedMembers.length,
      itemBuilder: (context, index) {
        final member = parsedMembers[index];
        final displayName = member['displayName']!;
        final userId = member['userId']!;
        final role = member['role']!;

        final isCurrentUser = _isCurrentUser(userId);
        final canManageMember = isCurrentUserAdmin && !isCurrentUser;
        final isAdmin = role == 'admin' || group.adminId == userId;

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
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: textTheme.titleMedium?.copyWith(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdmin
                          ? context.tr('groups_admin')
                          : context.tr('groups_member'),
                      style: textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Show role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isAdmin ? AppColors.primary : Colors.grey).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isAdmin ? AppColors.primary : Colors.grey)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  isAdmin
                      ? context.tr('groups_admin')
                      : context.tr('groups_member'),
                  style: TextStyle(
                    color: isAdmin ? AppColors.primary : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Show management options for admins
              if (canManageMember) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit_role') {
                      _showSimpleEditRoleDialog(
                        context,
                        displayName,
                        userId,
                        isAdmin,
                      );
                    } else if (value == 'remove') {
                      _showSimpleRemoveMemberDialog(
                        context,
                        displayName,
                        userId,
                      );
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit_role',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 16),
                              const SizedBox(width: 8),
                              Text(context.tr('groups_edit_role')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.remove_circle,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('groups_remove_member'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                  child: Icon(
                    Icons.more_vert,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Helper method to check if the current user is an admin of the group
  bool _isUserAdmin(ExpenseGroup group) {
    final supabase = SupabaseClientManager.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    // If we can't determine current user, we assume they're not admin
    if (currentUserId == null) return false;

    // Check if user is the group's admin
    return group.adminId == currentUserId;
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
                child: Text(context.tr('common_cancel')),
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
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
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

  Widget _buildDebtsTab(BuildContext context, ExpenseGroup group) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<GroupBloc, GroupState>(
      buildWhen: (previous, current) {
        // Only rebuild if we have new transaction data for this group
        if (current is SingleGroupLoaded &&
            current.group.id == widget.groupId) {
          if (previous is SingleGroupLoaded &&
              previous.group.id == widget.groupId) {
            return previous.transactions != current.transactions ||
                previous.group.isSettled != current.group.isSettled;
          }
          return true;
        }
        return false;
      },
      builder: (context, state) {
        final transactions =
            state is SingleGroupLoaded && state.group.id == widget.groupId
                ? state.transactions
                : null;

        return _buildDebtsContent(
          context,
          group,
          transactions,
          isDarkMode,
          textTheme,
        );
      },
    );
  }

  Widget _buildDebtsContent(
    BuildContext context,
    ExpenseGroup group,
    List<dynamic>? transactions,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    // Calculate optimized debts between members
    Map<String, double> netBalances =
        {}; // Positive = owed money, Negative = owes money

    // Create user ID to name mapping using the helper method
    final userIdToName = _createUserIdToNameMapping(group);

    // Initialize net balances for all known users
    for (var userId in userIdToName.keys) {
      netBalances[userId] = 0.0;
    }

    // If we don't have proper user ID mapping, try to build it from transactions
    if (transactions != null && transactions.isNotEmpty) {
      for (var transaction in transactions) {
        final payerId = transaction.paidBy;
        if (payerId != null && !userIdToName.containsKey(payerId)) {
          final displayName = _getDisplayNameForUserId(payerId, group);
          userIdToName[payerId] = displayName;
          netBalances[payerId] = 0.0;
        }
      }
    }

    // Calculate net balances based on approved transactions
    if (transactions != null && transactions.isNotEmpty) {
      for (var transaction in transactions) {
        if (transaction.approvalStatus == 'approved') {
          final payerId = transaction.paidBy;
          final amount = transaction.amount; // Use the actual signed amount
          final memberCount = userIdToName.length;

          if (memberCount > 0 && userIdToName.containsKey(payerId)) {
            final amountPerPerson = amount / memberCount;

            // For both income and expenses, the logic is the same:
            // The payer gets credit for the full amount, others get their share deducted
            netBalances[payerId] =
                (netBalances[payerId] ?? 0) + amount - amountPerPerson;
            for (var userId in userIdToName.keys) {
              if (userId != payerId) {
                netBalances[userId] =
                    (netBalances[userId] ?? 0) - amountPerPerson;
              }
            }
          }
        }
      }
    }

    // Create optimized debt settlements using a greedy algorithm
    List<Map<String, dynamic>> optimizedDebts = [];

    // Separate creditors (positive balance) and debtors (negative balance)
    List<MapEntry<String, double>> creditors = [];
    List<MapEntry<String, double>> debtors = [];

    for (var entry in netBalances.entries) {
      if (entry.value > 0.01) {
        // Small threshold to avoid floating point issues
        creditors.add(entry);
      } else if (entry.value < -0.01) {
        debtors.add(
          MapEntry(entry.key, -entry.value),
        ); // Make positive for easier calculation
      }
    }

    // Sort creditors and debtors by amount (largest first)
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    // Greedy algorithm to minimize number of transactions
    int creditorIndex = 0;
    int debtorIndex = 0;

    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];

      final creditorAmount = creditor.value;
      final debtorAmount = debtor.value;

      final settlementAmount = math.min(creditorAmount, debtorAmount);

      if (settlementAmount > 0.01) {
        // Only add meaningful debts
        optimizedDebts.add({
          'debtorId': debtor.key,
          'debtorName': userIdToName[debtor.key] ?? debtor.key,
          'creditorId': creditor.key,
          'creditorName': userIdToName[creditor.key] ?? creditor.key,
          'amount': settlementAmount,
        });
      }

      // Update remaining amounts
      creditors[creditorIndex] = MapEntry(
        creditor.key,
        creditorAmount - settlementAmount,
      );
      debtors[debtorIndex] = MapEntry(
        debtor.key,
        debtorAmount - settlementAmount,
      );

      // Move to next creditor or debtor if current one is settled
      if (creditors[creditorIndex].value <= 0.01) {
        creditorIndex++;
      }
      if (debtors[debtorIndex].value <= 0.01) {
        debtorIndex++;
      }
    }

    // Build UI for debts
    List<Widget> debtWidgets = [];

    // Add a header
    debtWidgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          context.tr('groups_debts_summary'),
          style: textTheme.titleLarge?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    // Add optimization summary
    if (optimizedDebts.isNotEmpty) {
      final totalDebtAmount = optimizedDebts.fold<double>(
        0.0,
        (sum, debt) => sum + debt['amount'],
      );

      debtWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('groups_debt_total_amount'),
                style: textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                '\$${totalDebtAmount.toStringAsFixed(2)}',
                style: textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If the group is settled, show a message
    if (group.isSettled) {
      debtWidgets.add(
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
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                context.tr('groups_all_settled'),
                style: textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('groups_no_debts'),
                style: textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      // Show all optimized debts
      bool hasDebts = optimizedDebts.isNotEmpty;

      for (var debt in optimizedDebts) {
        final debtorName = debt['debtorName'];
        final creditorName = debt['creditorName'];
        final amount = debt['amount'];

        // Show the debt card
        debtWidgets.add(
          Container(
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
                  backgroundColor: AppColors.expense.withValues(alpha: 0.2),
                  child: Text(
                    debtorName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: textTheme.bodyLarge?.copyWith(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: _getShortName(debtorName),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' ${context.tr('groups_owes')} '),
                            TextSpan(
                              text: _getShortName(creditorName),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      }

      // If no debts, show a message
      if (!hasDebts) {
        debtWidgets.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: isDarkMode ? Colors.white54 : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('groups_no_debts_yet'),
                  style: textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('groups_add_expenses_to_see_debts'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: debtWidgets,
      ),
    );
  }

  // Helper method to get a shorter display name
  String _getShortName(String fullName) {
    // Handle the "You" case
    if (fullName == 'You') {
      return 'You';
    }

    // For other names, use first name only if it's long enough
    final parts = fullName.split(' ');
    if (parts.length > 1 && parts.first.length > 2) {
      return parts.first;
    }

    // If name is short or single word, return as is
    return fullName;
  }

  // Helper method to show edit role dialog
  void _showSimpleEditRoleDialog(
    BuildContext context,
    String displayName,
    String userId,
    bool isAdmin,
  ) {
    String selectedRole = isAdmin ? 'admin' : 'member';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('groups_edit_role')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${context.tr('groups_member')}: $displayName',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        RadioListTile<String>(
                          title: Text(context.tr('groups_admin')),
                          value: 'admin',
                          groupValue: selectedRole,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedRole = value;
                              });
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                        RadioListTile<String>(
                          title: Text(context.tr('groups_member')),
                          value: 'member',
                          groupValue: selectedRole,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedRole = value;
                              });
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('common_cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (selectedRole != (isAdmin ? 'admin' : 'member')) {
                    context.read<GroupBloc>().add(
                      UpdateMemberRoleEvent(
                        groupId: widget.groupId,
                        userId: userId,
                        role: selectedRole,
                      ),
                    );
                  }
                },
                child: Text(context.tr('common_save')),
              ),
            ],
          ),
    );
  }

  // Helper method to show remove member dialog
  void _showSimpleRemoveMemberDialog(
    BuildContext context,
    String displayName,
    String userId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('groups_remove_member')),
            content: Text(
              '${context.tr('groups_remove_member_confirm')} $displayName?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('common_cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<GroupBloc>().add(
                    RemoveMemberEvent(groupId: widget.groupId, userId: userId),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(context.tr('common_remove')),
              ),
            ],
          ),
    );
  }

  // Helper method to check if the current user is the member
  bool _isCurrentUser(String userId) {
    final supabase = SupabaseClientManager.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    return currentUserId == userId;
  }

  // Helper method to parse group members and create user ID to name mapping
  Map<String, String> _createUserIdToNameMapping(ExpenseGroup group) {
    Map<String, String> userIdToName = {};

    for (var member in group.members) {
      // Extract user ID from member string if it contains it (format: "Name (userId)")
      final match = RegExp(r'^(.+?)\s*\(([^)]+)\)$').firstMatch(member);
      if (match != null) {
        final displayName = match.group(1)?.trim() ?? member;
        final userId = match.group(2);
        if (userId != null) {
          userIdToName[userId] = displayName;
        }
      } else {
        // If no ID in parentheses, the member string might be the display name
        // In this case, we'll store it but it might not match transaction user IDs
        userIdToName[member] = member;
      }
    }

    return userIdToName;
  }

  // Helper method to get display name for a user ID
  String _getDisplayNameForUserId(String userId, ExpenseGroup group) {
    final userIdToName = _createUserIdToNameMapping(group);

    // First try the mapping
    String? displayName = userIdToName[userId];

    if (displayName != null) {
      return displayName;
    }

    // Check if it's the current user
    final supabase = SupabaseClientManager.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (userId == currentUserId) {
      return 'You';
    }

    // Last resort: use a shortened user ID
    return 'User ${userId.substring(0, 8)}...';
  }
}
