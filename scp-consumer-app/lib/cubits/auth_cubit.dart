import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scp_mobile_shared/models/user_model.dart';
import 'package:scp_mobile_shared/services/auth_service.dart';

/// Auth State
class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  final UserModel? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }

  @override
  List<Object?> get props => [user, isLoading, isAuthenticated, error];
}

/// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit({
    AuthService? authService,
  })  : _authService = authService ?? AuthService(),
        super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      if (isAuthenticated) {
        final user = await _authService.getCurrentUser();
        emit(state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Login
  Future<void> login(String email, String password, {String role = 'consumer'}) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final response = await _authService.login(email, password, role: role);
      emit(state.copyWith(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Logout
  Future<void> logout() async {
    emit(state.copyWith(isLoading: true));

    try {
      await _authService.logout();
      emit(const AuthState());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Refresh token
  Future<void> refreshToken() async {
    try {
      await _authService.refreshToken();
    } catch (e) {
      // Handle error
    }
  }
}

