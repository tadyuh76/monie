import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';
import 'package:monie/features/groups/presentation/bloc/group_event.dart';
import 'package:monie/features/groups/presentation/bloc/group_state.dart';
import 'package:monie/features/groups/presentation/widgets/create_group_dialog.dart';
import 'package:monie/features/groups/presentation/pages/group_detail_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only reload data if we don't already have it
    final state = context.read<GroupBloc>().state;
    if (state is! GroupsLoaded) {
      _loadGroups();
    }
  }

  void _loadGroups() {
    // Avoid reloading if we're already loading
    final state = context.read<GroupBloc>().state;
    if (state is! GroupLoading) {
      context.read<GroupBloc>().add(const GetGroupsEvent());
    }
  }

  @override
  bool get wantKeepAlive => true; // Keep the state alive when navigating

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
        title: Text(
          context.tr('groups_title'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGroupDialog(context),
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ],
      ),
      body: BlocConsumer<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is GroupOperationSuccess) {
            // Only show snackbars for operations relevant to the groups list
            if (state.message.contains('Group created') ||
                state.message.contains('Group settled')) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
            // Only refresh if we need to
            if (context.read<GroupBloc>().state is! GroupsLoaded) {
              _loadGroups();
            }
          }
        },
        builder: (context, state) {
          if (state is GroupsLoaded) {
            return _buildGroupsContent(context, state.groups);
          } else if (state is GroupLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            // For other states (GroupInitial, GroupError), display empty content.
            // Users can use the refresh button to retry in case of an error.
            return _buildGroupsContent(context, []);
          }
        },
      ),
    );
  }

  Widget _buildGroupsContent(BuildContext context, List<ExpenseGroup> groups) {
    // Show a special message if groups is empty
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 64,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('groups_no_groups_yet'),
              style: TextStyle(
                fontSize: 18,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context),
              icon: const Icon(Icons.add),
              label: Text(context.tr('groups_create_new')),
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

    // Show the regular content when we have groups
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGroupsOverview(context, groups),
        const SizedBox(height: 24),
        ..._buildGroupsList(context, groups),
      ],
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }

  Widget _buildGroupsOverview(BuildContext context, List<ExpenseGroup> groups) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final totalAmount = groups.fold<double>(
      0,
      (sum, group) => sum + group.totalAmount,
    );

    final activeAmount = groups
        .where((g) => !g.isSettled)
        .fold<double>(0, (sum, group) => sum + group.totalAmount);

    final settledAmount = groups
        .where((g) => g.isSettled)
        .fold<double>(0, (sum, group) => sum + group.totalAmount);

    return Container(
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
            context.tr('groups_total_shared_expenses'),
            style: textTheme.titleLarge?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalAmount.toStringAsFixed(0)}',
            style: textTheme.headlineMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "${context.tr('groups_active')}: \$${activeAmount.toStringAsFixed(0)}",
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      isDarkMode
                          ? AppColors.textSecondary
                          : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "${context.tr('groups_settled')}: \$${settledAmount.toStringAsFixed(0)}",
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      isDarkMode
                          ? AppColors.textSecondary
                          : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupsList(
    BuildContext context,
    List<ExpenseGroup> groups,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          context.tr('groups_your_groups'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...groups.map(
        (group) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildGroupCard(context, group),
        ),
      ),

      // Add empty group card as the last item
      _buildEmptyGroupCard(context),
    ];
  }

  // Helper method to extract clean display name from member string
  String _getCleanDisplayName(String member) {
    // Extract display name from member string if it contains user ID (format: "Name (userId)")
    final match = RegExp(r'^(.+?)\s*\(([^)]+)\)$').firstMatch(member);
    if (match != null) {
      return match.group(1)?.trim() ?? member;
    }
    // If no ID in parentheses, return the member string as is
    return member;
  }

  Widget _buildGroupCard(BuildContext context, ExpenseGroup group) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        // Navigate to group details page with the group's ID
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => GroupDetailPage(groupId: group.id),
              ),
            )
            .then((_) {
              // Refresh groups when returning from the detail page
              _loadGroups();
            });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              group.isSettled
                  ? Border.all(
                    color:
                        isDarkMode
                            ? AppColors.textSecondary
                            : Colors.grey.shade400,
                    width: 1,
                  )
                  : null,
          boxShadow:
              !isDarkMode && !group.isSettled
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (group.isSettled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isDarkMode
                              ? AppColors.textSecondary
                              : Colors.grey.shade400)
                          .withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.tr('groups_settled'),
                      style: textTheme.bodySmall?.copyWith(
                        color:
                            isDarkMode
                                ? AppColors.textSecondary
                                : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('groups_total')}: \$${group.totalAmount.toStringAsFixed(0)}',
              style: textTheme.titleMedium?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr('groups_created')}: ${DateFormat('MMM d, yyyy').format(group.createdAt)}',
              style: textTheme.bodyMedium?.copyWith(
                color:
                    isDarkMode ? AppColors.textSecondary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Members
            Text(
              '${context.tr('groups_members')} (${group.members.length})',
              style: textTheme.titleSmall?.copyWith(
                color:
                    isDarkMode ? AppColors.textSecondary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  group.members.map((member) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? AppColors.surface
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getCleanDisplayName(member),
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
            ),

            if (!group.isSettled) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Calculate debts for this group
                      context.read<GroupBloc>().add(
                        CalculateDebtsEvent(groupId: group.id),
                      );

                      // Navigate to group details
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      GroupDetailPage(groupId: group.id),
                            ),
                          )
                          .then((_) {
                            // Refresh groups when returning from the detail page
                            _loadGroups();
                          });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDarkMode ? Colors.white : Colors.black87,
                      side: BorderSide(
                        color:
                            isDarkMode ? Colors.white30 : Colors.grey.shade400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(context.tr('groups_view_details')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/add-group-expense',
                        arguments: group.id,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(context.tr('groups_add_expense')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGroupCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showCreateGroupDialog(context),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? AppColors.divider : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow:
              !isDarkMode
                  ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 48,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('groups_create_new'),
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
