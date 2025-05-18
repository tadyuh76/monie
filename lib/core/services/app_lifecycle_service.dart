import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';

class AppLifecycleService with WidgetsBindingObserver {
  final NotificationBloc notificationBloc;
  AppLifecycleState? _previousState;
  String _lastReportedAppState = 'foreground';
  Timer? _hiddenStateTimer;
  
  AppLifecycleService({required this.notificationBloc}) {
    WidgetsBinding.instance.addObserver(this);
    // Initialize with foreground state
    notificationBloc.add(const SendAppStateChangeEvent(state: 'foreground'));
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('AppLifecycleState changed: ${_previousState?.name} -> ${state.name}');
    
    // Map Flutter lifecycle states to custom states
    String appState;
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and responding to user input
        appState = 'foreground';
        // Cancel any pending background notification
        _cancelHiddenStateTimer();
        break;
        
      case AppLifecycleState.inactive:
        // App is inactive (user switched tabs or pulled down notification shade)
        // Not send notifications for this state, but start a timer to detect if 
        // it transitions to a hidden state before paused
        _cancelHiddenStateTimer();
        _hiddenStateTimer = Timer(const Duration(milliseconds: 300), () {
          // If reach this point => in a "hidden" state between inactive and paused
          if (_previousState == AppLifecycleState.inactive) {
            debugPrint('Detected hidden state between inactive and paused');
            _reportStateChange('hidden');
          }
        });
        return; // Don't update previous state yet
        
      case AppLifecycleState.paused:
        // App is in the background
        appState = 'background';
        _cancelHiddenStateTimer();
        break;
        
      case AppLifecycleState.detached:
        // App is detached (likely terminated)
        appState = 'terminated';
        _cancelHiddenStateTimer();
        break;
        
      default:
        appState = 'background';
        _cancelHiddenStateTimer();
        break;
    }
    
    _reportStateChange(appState);
    _previousState = state;
  }
  
  void _reportStateChange(String appState) {
    // Only send notification if state actually changed
    if (_lastReportedAppState != appState) {
      debugPrint('App state changed: $_lastReportedAppState -> $appState');
      
      // Send the state change event to the notification bloc
      notificationBloc.add(SendAppStateChangeEvent(state: appState));
      _lastReportedAppState = appState;
    }
  }

  void _cancelHiddenStateTimer() {
    if (_hiddenStateTimer != null && _hiddenStateTimer!.isActive) {
      _hiddenStateTimer!.cancel();
      _hiddenStateTimer = null;
    }
  }
  
  void dispose() {
    _cancelHiddenStateTimer();
    WidgetsBinding.instance.removeObserver(this);
  }
}

