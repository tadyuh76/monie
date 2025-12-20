import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/add_reminder.dart';
import '../../domain/usecases/delete_reminder.dart';
import '../../domain/usecases/get_reminder.dart';
import '../../domain/usecases/get_all_reminders.dart';
import '../../domain/usecases/update_reminder.dart';
import 'daily_reminder_event.dart';
import 'daily_reminder_state.dart';

class DailyReminderBloc extends Bloc<DailyReminderEvent, DailyReminderState> {
  final GetReminder getReminder;
  final GetAllReminders getAllReminders;
  final AddReminder addReminder;
  final UpdateReminder updateReminder;
  final DeleteReminder deleteReminder;

  DailyReminderBloc({
    required this.getReminder,
    required this.getAllReminders,
    required this.addReminder,
    required this.updateReminder,
    required this.deleteReminder,
  }) : super(const DailyReminderInitial()) {
    on<LoadReminder>(_onLoadReminder);
    on<LoadAllReminders>(_onLoadAllReminders);
    on<AddReminderEvent>(_onAddReminder);
    on<UpdateReminderEvent>(_onUpdateReminder);
    on<DeleteReminderEvent>(_onDeleteReminder);
    on<ToggleReminderEvent>(_onToggleReminder);
  }

  Future<void> _onLoadReminder(
    LoadReminder event,
    Emitter<DailyReminderState> emit,
  ) async {
    emit(const DailyReminderLoading());
    
    final result = await getReminder();
    
    result.fold(
      (failure) => emit(DailyReminderError(failure.message)),
      (reminder) => emit(DailyReminderLoaded(reminder: reminder)),
    );
  }

  Future<void> _onLoadAllReminders(
    LoadAllReminders event,
    Emitter<DailyReminderState> emit,
  ) async {
    emit(const DailyReminderLoading());
    
    final result = await getAllReminders();
    
    result.fold(
      (failure) => emit(DailyReminderError(failure.message)),
      (reminders) => emit(AllRemindersLoaded(reminders)),
    );
  }

  Future<void> _onAddReminder(
    AddReminderEvent event,
    Emitter<DailyReminderState> emit,
  ) async {
    emit(const DailyReminderLoading());
    
    final result = await addReminder(
      AddReminderParams(
        hour: event.hour,
        minute: event.minute,
      ),
    );
    
    result.fold(
      (failure) => emit(DailyReminderError(failure.message)),
      (reminder) => emit(DailyReminderActionSuccess(
        message: 'Reminder set successfully!',
        reminder: reminder,
      )),
    );
  }

  Future<void> _onUpdateReminder(
    UpdateReminderEvent event,
    Emitter<DailyReminderState> emit,
  ) async {
    emit(const DailyReminderLoading());
    
    final result = await updateReminder(
      UpdateReminderParams(
        id: event.id,
        hour: event.hour,
        minute: event.minute,
        isEnabled: event.isEnabled,
      ),
    );
    
    result.fold(
      (failure) => emit(DailyReminderError(failure.message)),
      (reminder) => emit(DailyReminderActionSuccess(
        message: 'Reminder updated successfully!',
        reminder: reminder,
      )),
    );
  }

  Future<void> _onDeleteReminder(
    DeleteReminderEvent event,
    Emitter<DailyReminderState> emit,
  ) async {
    emit(const DailyReminderLoading());
    
    final result = await deleteReminder(event.id);
    
    result.fold(
      (failure) => emit(DailyReminderError(failure.message)),
      (_) => emit(const DailyReminderActionSuccess(
        message: 'Reminder deleted successfully!',
        reminder: null,
      )),
    );
  }

  Future<void> _onToggleReminder(
    ToggleReminderEvent event,
    Emitter<DailyReminderState> emit,
  ) async {
    emit(const DailyReminderLoading());
    
    final result = await updateReminder(
      UpdateReminderParams(
        id: event.reminder.id,
        isEnabled: !event.reminder.isEnabled,
      ),
    );
    
    result.fold(
      (failure) => emit(DailyReminderError(failure.message)),
      (reminder) => emit(DailyReminderActionSuccess(
        message: reminder.isEnabled 
            ? 'Reminder enabled' 
            : 'Reminder disabled',
        reminder: reminder,
      )),
    );
  }
}
