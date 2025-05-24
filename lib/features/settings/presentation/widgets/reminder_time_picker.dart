import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/core/localization/app_localizations.dart';

class ReminderTimePicker extends StatefulWidget {
  final List<ReminderTime> initialReminders;
  final Function(List<ReminderTime>) onRemindersChanged;

  const ReminderTimePicker({
    Key? key,
    required this.initialReminders,
    required this.onRemindersChanged,
  }) : super(key: key);

  @override
  State<ReminderTimePicker> createState() => _ReminderTimePickerState();
}

class _ReminderTimePickerState extends State<ReminderTimePicker> {
  late List<ReminderTime> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List<ReminderTime>.from(widget.initialReminders);
  }

  void _addReminder() {
    setState(() {
      _reminders.add(const ReminderTime(hour: 9, minute: 0));
    });
    widget.onRemindersChanged(_reminders);
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
    widget.onRemindersChanged(_reminders);
  }

  void _toggleReminder(int index) {
    setState(() {
      _reminders[index] = _reminders[index].copyWith(
        enabled: !_reminders[index].enabled,
      );
    });
    widget.onRemindersChanged(_reminders);
  }

  Future<void> _editReminderTime(int index) async {
    final currentReminder = _reminders[index];
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentReminder.hour,
        minute: currentReminder.minute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              hourMinuteTextColor: Theme.of(context).textTheme.bodyLarge?.color,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: Theme.of(context).cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _reminders[index] = _reminders[index].copyWith(
          hour: pickedTime.hour,
          minute: pickedTime.minute,
        );
      });
      widget.onRemindersChanged(_reminders);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('settings_transaction_reminders'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_reminders.length < 5) // Limit to 5 reminders max
                IconButton(
                  onPressed: _addReminder,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                  tooltip: context.tr('settings_add_reminder'),
                ),
            ],
          ),
        ),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            context.tr('settings_reminder_description'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Reminder list
        if (_reminders.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('settings_no_reminders'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addReminder,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('settings_add_first_reminder')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reminders.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.divider : Colors.black.withOpacity(0.05),
            ),
            itemBuilder: (context, index) {
              final reminder = _reminders[index];
              return ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: reminder.enabled ? AppColors.primary : Colors.grey,
                ),
                title: Text(
                  reminder.formattedTime,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: reminder.enabled 
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5),
                  ),
                ),
                subtitle: Text(
                  reminder.enabled 
                      ? context.tr('settings_reminder_enabled')
                      : context.tr('settings_reminder_disabled'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: reminder.enabled ? AppColors.primary : Colors.grey,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch.adaptive(
                      value: reminder.enabled,
                      onChanged: (_) => _toggleReminder(index),
                      activeColor: AppColors.primary,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editReminderTime(index);
                            break;
                          case 'delete':
                            _removeReminder(index);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              const SizedBox(width: 12),
                              Text(context.tr('settings_edit_time')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 20, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('settings_delete_reminder'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: reminder.enabled ? () => _editReminderTime(index) : null,
              );
            },
          ),
      ],
    );
  }
}
