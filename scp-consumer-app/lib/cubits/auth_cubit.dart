import 'dart:async';
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
  Timer? _checkAuthTimer;
  bool _isClosed = false;

  AuthCubit({
    AuthService? authService,
  })  : _authService = authService ?? AuthService(),
        super(const AuthState()) {
    // Don't block constructor - check auth status asynchronously after app starts
    // This prevents app from being killed during startup (Android kills apps that take >3 seconds)
    _checkAuthStatus();
  }

  @override
  Future<void> close() {
    _isClosed = true;
    _checkAuthTimer?.cancel();
    return super.close();
  }

  /// Check if user is already authenticated
  /// This is non-blocking and won't cause app to be killed
  Future<void> _checkAuthStatus() async {
    // Add small delay to let app start first
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Check if cubit is closed before proceeding
    if (_isClosed || isClosed) return;
    
    print('🔐 [AUTH] Checking authentication status...');
    if (!_isClosed && !isClosed) {
      emit(state.copyWith(isLoading: true));
    }
    
    try {
      // Add timeout to prevent hanging if backend is unreachable
      print('🔐 [AUTH] Checking if user is authenticated...');
      final isAuthenticated = await _authService.isAuthenticated()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print('⏱️  [AUTH] Authentication check timeout - assuming not authenticated');
              // If timeout, assume not authenticated to allow app to start
              return false;
            },
          );
      
      // Check if cubit is closed before emitting
      if (_isClosed || isClosed) return;
      
      print('🔐 [AUTH] Is authenticated: $isAuthenticated');
      
      if (isAuthenticated) {
        print('👤 [AUTH] Loading user data...');
        final user = await _authService.getCurrentUser()
            .timeout(
              const Duration(seconds: 1),
              onTimeout: () {
                print('⏱️  [AUTH] User data load timeout');
                return null;
              },
            );
        
        // Check if cubit is closed before emitting
        if (_isClosed || isClosed) return;
        
        if (user != null) {
          print('✅ [AUTH] User authenticated: ${user.email}');
          emit(state.copyWith(
            isAuthenticated: true,
            user: user,
            isLoading: false,
          ));
        } else {
          print('⚠️  [AUTH] User data not available');
          emit(state.copyWith(isLoading: false));
        }
      } else {
        print('ℹ️  [AUTH] User not authenticated - showing login screen');
        emit(state.copyWith(isLoading: false));
      }
    } catch (e, stackTrace) {
      // Check if cubit is closed before emitting
      if (_isClosed || isClosed) return;
      
      print('═══════════════════════════════════════');
      print('❌ [AUTH] ERROR CHECKING AUTH STATUS');
      print('═══════════════════════════════════════');
      print('Error: $e');
      print('Stack: $stackTrace');
      print('═══════════════════════════════════════');
      // On any error, just show login screen - don't crash
      emit(state.copyWith(isLoading: false, isAuthenticated: false));
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

