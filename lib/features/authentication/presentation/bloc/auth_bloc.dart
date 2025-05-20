import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/authentication/domain/usecases/check_email_exists.dart';
import 'package:monie/features/authentication/domain/usecases/get_current_user.dart';
import 'package:monie/features/authentication/domain/usecases/is_email_verified.dart';
import 'package:monie/features/authentication/domain/usecases/resend_verification_email.dart';
import 'package:monie/features/authentication/domain/usecases/reset_password.dart';
import 'package:monie/features/authentication/domain/usecases/sign_in.dart';
import 'package:monie/features/authentication/domain/usecases/sign_out.dart';
import 'package:monie/features/authentication/domain/usecases/sign_up.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser _getCurrentUser;
  final SignUp _signUp;
  final SignIn _signIn;
  final SignOut _signOut;
  final ResendVerificationEmail _resendVerificationEmail;
  final IsEmailVerified _isEmailVerified;
  final ResetPassword _resetPassword;
  final CheckEmailExists _checkEmailExists;

  // Track last email send time
  final Map<String, DateTime> _lastVerificationEmails = {};

  AuthBloc({
    required GetCurrentUser getCurrentUser,
    required SignUp signUp,
    required SignIn signIn,
    required SignOut signOut,
    required ResendVerificationEmail resendVerificationEmail,
    required IsEmailVerified isEmailVerified,
    required ResetPassword resetPassword,
    required CheckEmailExists checkEmailExists,
  }) : _getCurrentUser = getCurrentUser,
       _signUp = signUp,
       _signIn = signIn,
       _signOut = signOut,
       _resendVerificationEmail = resendVerificationEmail,
       _isEmailVerified = isEmailVerified,
       _resetPassword = resetPassword,
       _checkEmailExists = checkEmailExists,
       super(AuthInitial()) {
    on<GetCurrentUserEvent>(_onGetCurrentUser);
    on<RefreshUserEvent>(_onRefreshUser);
    on<SignUpEvent>(_onSignUp);
    on<SignInEvent>(_onSignIn);
    on<SignOutEvent>(_onSignOut);
    on<ResendVerificationEmailEvent>(_onResendVerificationEmail);
    on<CheckVerificationStatusEvent>(_onCheckVerificationStatus);
    on<ResetPasswordEvent>(_onResetPassword);
    on<CheckEmailExistsEvent>(_onCheckEmailExists);
  }

  Future<void> _onRefreshUser(
    RefreshUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Simply re-use the getCurrentUser handler
    await _onGetCurrentUser(GetCurrentUserEvent(), emit);
  }

  Future<void> _onGetCurrentUser(
    GetCurrentUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _getCurrentUser();

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final params = SignUpParams(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
      profileImageUrl: event.profileImageUrl,
      colorMode: event.colorMode,
      language: event.language,
    );

    final result = await _signUp(params);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(SignUpSuccess(event.email)),
    );
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final params = SignInParams(email: event.email, password: event.password);

    final result = await _signIn(params);

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      emit(Authenticated(user));
    });
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _signOut();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onResendVerificationEmail(
    ResendVerificationEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Check if the email was sent recently (within 2 minutes)
    final now = DateTime.now();
    final lastSent = _lastVerificationEmails[event.email];

    if (lastSent != null && now.difference(lastSent).inSeconds < 120) {
      // If email was sent too recently, emit a special state
      emit(
        AuthError('Please wait before requesting another verification email'),
      );
      return;
    }

    emit(AuthLoading());

    final params = ResendVerificationEmailParams(email: event.email);
    final result = await _resendVerificationEmail(params);

    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      // Track this email send time
      _lastVerificationEmails[event.email] = now;
      emit(VerificationEmailSent(event.email));
    });
  }

  Future<void> _onCheckVerificationStatus(
    CheckVerificationStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Only emit loading state for non-silent checks
    if (!event.isSilent) {
      emit(AuthLoading());
    }

    final params = IsEmailVerifiedParams(email: event.email);
    final result = await _isEmailVerified(params);

    result.fold(
      (failure) {
        // Only emit error states for non-silent checks
        if (!event.isSilent) {
          emit(AuthError(failure.message));
        }
      },
      (isVerified) {
        if (isVerified) {
          // Always emit when verified (this triggers navigation)
          emit(VerificationSuccess());
        } else if (!event.isSilent) {
          // Only emit non-verified status for explicit checks
          emit(VerificationPending());
        }
      },
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final params = ResetPasswordParams(email: event.email);
    final result = await _resetPassword(params);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(PasswordResetEmailSent(event.email)),
    );
  }

  Future<void> _onCheckEmailExists(
    CheckEmailExistsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final params = CheckEmailExistsParams(email: event.email);
    final result = await _checkEmailExists(params);

    result.fold((failure) => emit(AuthError(failure.message)), (status) {
      if (status['exists'] == true) {
        if (status['verified'] == true) {
          emit(EmailExists(canSignIn: true));
        } else {
          emit(EmailExists(canSignIn: false));
        }
      } else {
        emit(EmailDoesNotExist());
      }
    });
  }
}
