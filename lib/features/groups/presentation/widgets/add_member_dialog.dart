import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';
import 'package:monie/features/groups/presentation/bloc/group_event.dart';

class AddMemberDialog extends StatefulWidget {
  final String groupId;

  const AddMemberDialog({super.key, required this.groupId});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'editor';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(context.tr('groups_add_member')),
      backgroundColor: isDarkMode ? AppColors.surface : Colors.white,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: context.tr('email'),
                hintText: 'example@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('email_required');
                }
                // Simple email validation
                if (!value.contains('@') || !value.contains('.')) {
                  return context.tr('email_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: context.tr('groups_role'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedRole,
              items: [
                DropdownMenuItem(
                  value: 'editor',
                  child: Text(context.tr('groups_role_editor')),
                ),
                DropdownMenuItem(
                  value: 'viewer',
                  child: Text(context.tr('groups_role_viewer')),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: Text(context.tr('groups_role_admin')),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _addMember,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(context.tr('add')),
        ),
      ],
    );
  }

  void _addMember() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();

      // Add the member using GroupBloc
      context.read<GroupBloc>().add(
        AddMemberEvent(
          groupId: widget.groupId,
          email: email,
          role: _selectedRole,
        ),
      );

      Navigator.pop(context);
    }
  }
}
