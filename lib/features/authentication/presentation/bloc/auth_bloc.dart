import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';
import 'package:monie/features/authentication/domain/usecases/check_email_verified.dart';
import 'package:monie/features/authentication/domain/usecases/get_signed_in_user.dart';
import 'package:monie/features/authentication/domain/usecases/sign_in.dart';
import 'package:monie/features/authentication/domain/usecases/sign_out.dart';
import 'package:monie/features/authentication/domain/usecases/sign_up.dart';
import 'package:monie/features/authentication/domain/usecases/update_email.dart';
import 'package:monie/features/authentication/domain/usecases/verify_email.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const SignUpEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
}

class SignOutEvent extends AuthEvent {}

class CheckEmailVerificationEvent extends AuthEvent {}

class SendEmailVerificationEvent extends AuthEvent {}

class UpdateEmailEvent extends AuthEvent {
  final String newEmail;

  const UpdateEmailEvent({required this.newEmail});

  @override
  List<Object> get props => [newEmail];
}

class ResetAuthEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class EmailVerificationSent extends AuthState {}

class EmailUpdateSent extends AuthState {}

class EmailVerificationStatus extends AuthState {
  final bool isVerified;

  const EmailVerificationStatus({required this.isVerified});

  @override
  List<Object?> get props => [isVerified];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;
  final GetSignedInUser getSignedInUser;
  final CheckEmailVerified checkEmailVerified;
  final VerifyEmail verifyEmail;
  final UpdateEmail updateEmail;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.getSignedInUser,
    required this.checkEmailVerified,
    required this.verifyEmail,
    required this.updateEmail,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInEvent>(_onSignIn);
    on<SignUpEvent>(_onSignUp);
    on<SignOutEvent>(_onSignOut);
    on<CheckEmailVerificationEvent>(_onCheckEmailVerification);
    on<SendEmailVerificationEvent>(_onSendEmailVerification);
    on<UpdateEmailEvent>(_onUpdateEmail);
    on<ResetAuthEvent>(_onResetAuth);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final userResult = await getSignedInUser();
    userResult.fold(
      (failure) => emit(Unauthenticated()),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await signIn(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await signUp(
        SignUpParams(
          email: event.email,
          password: event.password,
          name: event.name,
        ),
      );

      result.fold((failure) => emit(AuthError(message: failure.message)), (
        user,
      ) {
        // After successful registration, we know email verification is needed
        emit(Authenticated(user: user));

        // Immediately check email verification status
        add(CheckEmailVerificationEvent());
      });
    } catch (e) {
      emit(
        AuthError(
          message: 'Unexpected error during registration: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await signOut(NoParams());

    // Use a short delay to ensure UI transitions smoothly
    await Future.delayed(const Duration(milliseconds: 100));

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onCheckEmailVerification(
    CheckEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await checkEmailVerified(NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (isVerified) => emit(EmailVerificationStatus(isVerified: isVerified)),
    );
  }

  Future<void> _onSendEmailVerification(
    SendEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await verifyEmail(NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(EmailVerificationSent()),
    );
  }

  Future<void> _onUpdateEmail(
    UpdateEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await updateEmail(
      UpdateEmailParams(newEmail: event.newEmail),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(EmailUpdateSent()),
    );
  }

  void _onResetAuth(ResetAuthEvent event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}
