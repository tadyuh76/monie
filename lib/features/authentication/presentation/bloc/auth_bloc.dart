import 'package:bloc/bloc.dart';
import 'package:monie/features/authentication/domain/usecases/check_email_exists.dart';
import 'package:monie/features/authentication/domain/usecases/get_current_user.dart';
import 'package:monie/features/authentication/domain/usecases/is_email_verified.dart';
import 'package:monie/features/authentication/domain/usecases/reset_password.dart';
import 'package:monie/features/authentication/domain/usecases/resend_verification_email.dart';
import 'package:monie/features/authentication/domain/usecases/sign_in.dart';
import 'package:monie/features/authentication/domain/usecases/sign_out.dart';
import 'package:monie/features/authentication/domain/usecases/sign_up.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final SignUp signUp;
  final SignIn signIn;
  final SignOut signOut;
  final ResendVerificationEmail resendVerificationEmail;
  final IsEmailVerified isEmailVerified;
  final ResetPassword resetPassword;
  final CheckEmailExists checkEmailExists;

  // Track last email send time
  final Map<String, DateTime> _lastVerificationEmails = {};

  AuthBloc({
    required this.getCurrentUser,
    required this.signUp,
    required this.signIn,
    required this.signOut,
    required this.resendVerificationEmail,
    required this.isEmailVerified,
    required this.resetPassword,
    required this.checkEmailExists,
  }) : super(AuthInitial()) {
    on<GetCurrentUserEvent>(_onGetCurrentUser);
    on<SignUpEvent>(_onSignUp);
    on<SignInEvent>(_onSignIn);
    on<SignOutEvent>(_onSignOut);
    on<ResendVerificationEmailEvent>(_onResendVerificationEmail);
    on<CheckEmailVerificationEvent>(_onCheckEmailVerification);
    on<ResetPasswordEvent>(_onResetPassword);
    on<CheckEmailExistsEvent>(_onCheckEmailExists);
  }

  Future<void> _onGetCurrentUser(
    GetCurrentUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await getCurrentUser();
    result.fold(
      (failure) => emit(Unauthenticated()),
      (user) =>
          user != null ? emit(Authenticated(user)) : emit(Unauthenticated()),
    );
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final params = SignUpParams(email: event.email, password: event.password);
    final result = await signUp(params);

    await result.fold(
      (failure) async {
        // Check if this is an "Email already registered" error which is actually ok
        if (failure.message.contains('already registered') ||
            failure.message.contains('already exists')) {
          // Just emit SignUpSuccess to let the UI navigate to verification page
          emit(SignUpSuccess(event.email));
        } else {
          emit(AuthError(failure.message));
        }
      },
      (_) async {
        // Skip sign-in attempt since email verification is required
        // Directly emit SignUpSuccess to navigate to the verification page
        emit(SignUpSuccess(event.email));
      },
    );
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // First check if email exists and is verified
    final existsParams = CheckEmailExistsParams(email: event.email);
    final existsResult = await checkEmailExists(existsParams);

    await existsResult.fold(
      (failure) async {
        // Continue with normal sign-in if we can't check verification status
        final params = SignInParams(
          email: event.email,
          password: event.password,
        );
        final result = await signIn(params);
        result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(Authenticated(user)),
        );
      },
      (emailStatus) async {
        final exists = emailStatus['exists'] ?? false;
        final verified = emailStatus['verified'] ?? false;

        if (exists && !verified) {
          // Email exists but is not verified - direct to verification page
          emit(SignUpSuccess(event.email));
          return;
        }

        // Otherwise proceed with normal sign-in
        final params = SignInParams(
          email: event.email,
          password: event.password,
        );
        final result = await signIn(params);
        result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(Authenticated(user)),
        );
      },
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await signOut();
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
    final result = await resendVerificationEmail(params);

    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      // Track this email send time
      _lastVerificationEmails[event.email] = now;
      emit(VerificationEmailSent(event.email));
    });
  }

  Future<void> _onCheckEmailVerification(
    CheckEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Only emit loading state for non-silent checks
    if (!event.isSilent) {
      emit(AuthLoading());
    }

    final params = IsEmailVerifiedParams(email: event.email);
    final result = await isEmailVerified(params);

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
          emit(EmailVerificationStatus(isVerified));
        } else if (!event.isSilent) {
          // Only emit non-verified status for explicit checks
          emit(EmailVerificationStatus(isVerified));
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
    final result = await resetPassword(params);
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
    final result = await checkEmailExists(params);

    result.fold((failure) => emit(AuthError(failure.message)), (emailStatus) {
      final exists = emailStatus['exists'] ?? false;
      final verified = emailStatus['verified'] ?? false;

      emit(
        EmailExistsState(
          exists: exists,
          verified: verified,
          email: event.email,
        ),
      );
    });
  }
}
