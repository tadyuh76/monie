import 'package:flutter/material.dart';
import 'package:monie/features/home/domain/entities/account.dart';

class SelectAccountsModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A2323),
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
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...accounts.map((account) {
            final isPinned = pinnedAccountIds.contains(account.id);
            return ListTile(
              leading: Icon(
                Icons.push_pin,
                color: isPinned ? Colors.orange : Colors.brown[300],
                size: 28,
              ),
              title: Text(
                account.name,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              onTap: () => onPinToggle(account.id, !isPinned),
            );
          }),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onAddAccount,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 32, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- UI Preview for development ---
class SelectAccountsModalPreview extends StatefulWidget {
  const SelectAccountsModalPreview({super.key});

  @override
  State<SelectAccountsModalPreview> createState() => _SelectAccountsModalPreviewState();
}

class _SelectAccountsModalPreviewState extends State<SelectAccountsModalPreview> {
  late Set<String> pinned;

  final accounts = const [
    Account(id: '1', name: 'Ngân hàng', type: 'bank', balance: 1000000, currency: 'VND', transactionCount: 6),
    Account(id: '2', name: 'Dubject', type: 'cash', balance: 360000, currency: 'VND', transactionCount: 1),
    Account(id: '3', name: 'Dora', type: 'credit', balance: 0, currency: 'VND', transactionCount: 0),
  ];

  @override
  void initState() {
    super.initState();
    pinned = {'1', '2'};
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: 400,
          child: SelectAccountsModal(
            accounts: accounts,
            pinnedAccountIds: pinned,
            onPinToggle: (id, isPinned) {
              setState(() {
                if (isPinned) {
                  pinned.add(id);
                } else {
                  pinned.remove(id);
                }
              });
            },
            onEdit: () {},
            onAddAccount: () {},
          ),
        ),
      ),
    );
  }
} 