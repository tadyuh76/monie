import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/daily_reminder_bloc.dart';
import '../bloc/daily_reminder_event.dart';
import '../bloc/daily_reminder_state.dart';
import '../widgets/reminder_card.dart';
import '../widgets/time_picker_dialog.dart' as custom;

class DailyReminderPage extends StatefulWidget {
  const DailyReminderPage({super.key});

  @override
  State<DailyReminderPage> createState() => _DailyReminderPageState();
}

class _DailyReminderPageState extends State<DailyReminderPage> {
  @override
  void initState() {
    super.initState();
    // Load all reminders instead of just one
    context.read<DailyReminderBloc>().add(const LoadAllReminders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reminder'),
      ),
      body: BlocConsumer<DailyReminderBloc, DailyReminderState>(
        listener: (context, state) {
          if (state is DailyReminderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DailyReminderActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Reload all reminders after action
            context.read<DailyReminderBloc>().add(const LoadAllReminders());
          }
        },
        builder: (context, state) {
          if (state is DailyReminderLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Handle multiple reminders
          if (state is AllRemindersLoaded) {
            return _buildContentWithReminders(context, state.reminders);
          }

          // Fallback for single reminder (backward compatibility)
          if (state is DailyReminderLoaded) {
            return _buildContent(context, state.reminder);
          }

          if (state is DailyReminderActionSuccess) {
            return _buildContent(context, state.reminder);
          }

          // No reminders - show empty state
          return _buildContentWithReminders(context, []);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, reminder) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set a daily reminder to check your expenses',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          if (reminder != null) ...[
            ReminderCard(
              reminder: reminder,
              onToggle: () {
                context.read<DailyReminderBloc>().add(
                      ToggleReminderEvent(reminder),
                    );
              },
              onEdit: () async {
                final result = await showDialog<TimeOfDay>(
                  context: context,
                  builder: (context) => custom.TimePickerDialog(
                    initialTime: TimeOfDay(
                      hour: reminder.hour,
                      minute: reminder.minute,
                    ),
                  ),
                );

                if (result != null && context.mounted) {
                  context.read<DailyReminderBloc>().add(
                        UpdateReminderEvent(
                          id: reminder.id,
                          hour: result.hour,
                          minute: result.minute,
                        ),
                      );
                }
              },
              onDelete: () {
                context.read<DailyReminderBloc>().add(
                      DeleteReminderEvent(reminder.id),
                    );
              },
            ),
          ] else ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reminder set',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<TimeOfDay>(
                        context: context,
                        builder: (context) => const custom.TimePickerDialog(),
                      );

                      if (result != null && context.mounted) {
                        context.read<DailyReminderBloc>().add(
                              AddReminderEvent(
                                hour: result.hour,
                                minute: result.minute,
                              ),
                            );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Set Reminder'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentWithReminders(BuildContext context, List<dynamic> reminders) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Reminders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reminders are delivered via push notifications',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: reminders.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    itemCount: reminders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      return ReminderCard(
                        reminder: reminder,
                        onToggle: () {
                          context.read<DailyReminderBloc>().add(
                                ToggleReminderEvent(reminder),
                              );
                        },
                        onEdit: () async {
                          final result = await showDialog<TimeOfDay>(
                            context: context,
                            builder: (context) => custom.TimePickerDialog(
                              initialTime: TimeOfDay(
                                hour: reminder.hour,
                                minute: reminder.minute,
                              ),
                            ),
                          );

                          if (result != null && context.mounted) {
                            context.read<DailyReminderBloc>().add(
                                  UpdateReminderEvent(
                                    id: reminder.id,
                                    hour: result.hour,
                                    minute: result.minute,
                                  ),
                                );
                          }
                        },
                        onDelete: () {
                          context.read<DailyReminderBloc>().add(
                                DeleteReminderEvent(reminder.id),
                              );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog<TimeOfDay>(
                  context: context,
                  builder: (context) => const custom.TimePickerDialog(),
                );

                if (result != null && context.mounted) {
                  context.read<DailyReminderBloc>().add(
                        AddReminderEvent(
                          hour: result.hour,
                          minute: result.minute,
                        ),
                      );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Reminder'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders set',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first reminder',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
