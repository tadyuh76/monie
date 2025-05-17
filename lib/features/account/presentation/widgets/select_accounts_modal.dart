import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/home/domain/entities/account.dart';

class SelectAccountsModal extends StatefulWidget {
  final List<Account> accounts;
  final Set<String> pinnedAccountIds;
  final void Function(String accountId, bool pinned) onPinToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onAddAccount;

  const SelectAccountsModal({
    super.key,
    required this.accounts,
    required this.pinnedAccountIds,
    required this.onPinToggle,
    this.onEdit,
    this.onAddAccount,
  });

  @override
  State<SelectAccountsModal> createState() => _SelectAccountsModalState();
}

class _SelectAccountsModalState extends State<SelectAccountsModal> {
  late Set<String> localPinned;

  @override
  void initState() {
    super.initState();
    localPinned = Set<String>.from(widget.pinnedAccountIds);
  }

  void _handlePinToggle(String accountId, bool isPinned) {
    setState(() {
      if (isPinned) {
        localPinned.add(accountId);
      } else {
        localPinned.remove(accountId);
      }
    });
    // Notify parent after UI update for instant feedback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPinToggle(accountId, isPinned);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Select Accounts',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: widget.onEdit,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.accounts.map((account) {
            final isPinned = localPinned.contains(account.id);
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handlePinToggle(account.id, !isPinned),               
                // ignore: deprecated_member_use
                splashColor:  Colors.white.withOpacity(0.3),
                highlightColor: Colors.white,
                child: ListTile(
                  leading: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? AppColors.primary : Colors.white54,
                    size: 28,
                  ),
                  title: Text(
                    account.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  tileColor: Colors.transparent,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onAddAccount,
            // ignore: deprecated_member_use
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor:Colors.white,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1.5),
                color: AppColors.background,
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 28, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Add Account', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 