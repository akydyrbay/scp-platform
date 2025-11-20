import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scp_mobile_shared/models/user_model.dart';
import 'package:scp_mobile_shared/services/auth_service.dart';
import '../lib/cubits/auth_cubit.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('AuthCubit (Supplier)', () {
    late AuthCubit authCubit;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    tearDown(() {
      authCubit.close();
    });

    test('initial state is not authenticated', () {
      authCubit = AuthCubit(authService: mockAuthService, skipInitialCheck: true);
      expect(authCubit.state.isAuthenticated, isFalse);
      expect(authCubit.state.isLoading, isFalse);
      expect(authCubit.state.user, isNull);
    });

    blocTest<AuthCubit, AuthState>(
      'login succeeds and sets authenticated state',
      build: () {
        when(() => mockAuthService.login(
          'test@example.com',
          'password123',
          role: 'sales_rep',
        )).thenAnswer((_) async => LoginResponse(
          user: UserModel(
            id: 'user1',
            email: 'test@example.com',
            firstName: 'Test',
            lastName: 'User',
            role: 'sales_rep',
            createdAt: DateTime.now(),
          ),
          accessToken: 'token',
          refreshToken: 'refresh',
        ));
        when(() => mockAuthService.isAuthenticated()).thenAnswer((_) async => false);
        return AuthCubit(authService: mockAuthService, skipInitialCheck: true);
      },
      act: (cubit) => cubit.login('test@example.com', 'password123', role: 'sales_rep'),
      wait: const Duration(milliseconds: 200), // Wait for _checkAuthStatus
      expect: () => [
        predicate<AuthState>((state) => state.isLoading == true),
        predicate<AuthState>((state) =>
          state.isAuthenticated == true &&
          state.user != null &&
          state.user!.email == 'test@example.com' &&
          state.isLoading == false),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login handles errors correctly',
      build: () {
        when(() => mockAuthService.login(
          'test@example.com',
          'wrongpassword',
          role: 'sales_rep',
        )).thenThrow(Exception('Invalid credentials'));
        when(() => mockAuthService.isAuthenticated()).thenAnswer((_) async => false);
        return AuthCubit(authService: mockAuthService, skipInitialCheck: true);
      },
      act: (cubit) => cubit.login('test@example.com', 'wrongpassword', role: 'sales_rep'),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        predicate<AuthState>((state) => state.isLoading == true),
        predicate<AuthState>((state) =>
          state.isLoading == false &&
          state.error != null &&
          state.error!.contains('Invalid credentials')),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout clears authentication state',
      build: () {
        when(() => mockAuthService.logout()).thenAnswer((_) async => {});
        when(() => mockAuthService.isAuthenticated()).thenAnswer((_) async => true);
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => UserModel(
          id: 'user1',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          role: 'sales_rep',
          createdAt: DateTime.now(),
        ));
        return AuthCubit(authService: mockAuthService, skipInitialCheck: true);
      },
      seed: () => AuthState(
        user: UserModel(
          id: 'user1',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          role: 'sales_rep',
          createdAt: DateTime.now(),
        ),
        isAuthenticated: true,
      ),
      act: (cubit) => cubit.logout(),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        predicate<AuthState>((state) => state.isLoading == true),
        predicate<AuthState>((state) =>
          state.isAuthenticated == false &&
          state.user == null &&
          state.isLoading == false),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'logout handles errors correctly',
      build: () {
        when(() => mockAuthService.logout()).thenThrow(Exception('Logout failed'));
        when(() => mockAuthService.isAuthenticated()).thenAnswer((_) async => false);
        return AuthCubit(authService: mockAuthService, skipInitialCheck: true);
      },
      seed: () => AuthState(
        user: UserModel(
          id: 'user1',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          role: 'sales_rep',
          createdAt: DateTime.now(),
        ),
        isAuthenticated: true,
      ),
      act: (cubit) => cubit.logout(),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        predicate<AuthState>((state) => state.isLoading == true),
        predicate<AuthState>((state) =>
          state.isLoading == false &&
          state.error != null &&
          state.error!.contains('Logout failed')),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'refreshToken calls service',
      build: () {
        when(() => mockAuthService.refreshToken()).thenAnswer((_) async => 'new_token');
        when(() => mockAuthService.isAuthenticated()).thenAnswer((_) async => false);
        return AuthCubit(authService: mockAuthService, skipInitialCheck: true);
      },
      act: (cubit) => cubit.refreshToken(),
      wait: const Duration(milliseconds: 200),
      verify: (_) {
        verify(() => mockAuthService.refreshToken()).called(1);
      },
    );
  });
}

