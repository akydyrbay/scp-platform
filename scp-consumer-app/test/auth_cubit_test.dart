import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:scp_consumer_app/cubits/auth_cubit.dart';
import 'package:scp_mobile_shared/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('AuthCubit', () {
    late AuthCubit authCubit;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      // Mock isAuthenticated to return false immediately to avoid async delays
      when(() => mockAuthService.isAuthenticated()).thenAnswer((_) async => false);
      authCubit = AuthCubit(authService: mockAuthService);
    });

    tearDown(() async {
      // Wait a bit for any pending async operations
      await Future.delayed(const Duration(milliseconds: 150));
      await authCubit.close();
    });

    test('initial state is not authenticated', () async {
      // Wait for _checkAuthStatus to complete
      await Future.delayed(const Duration(milliseconds: 150));
      expect(authCubit.state.isAuthenticated, isFalse);
      expect(authCubit.state.user, isNull);
      expect(authCubit.state.error, isNull);
    });

    blocTest<AuthCubit, AuthState>(
      'logout emits unauthenticated state',
      build: () {
        final mockService = MockAuthService();
        when(() => mockService.isAuthenticated()).thenAnswer((_) async => false);
        when(() => mockService.logout()).thenAnswer((_) async => {});
        return AuthCubit(authService: mockService);
      },
      wait: const Duration(milliseconds: 200), // Wait for _checkAuthStatus to complete
      act: (cubit) async {
        await cubit.logout();
      },
      verify: (cubit) {
        // Verify final state after logout
        expect(cubit.state.isAuthenticated, isFalse);
        expect(cubit.state.isLoading, isFalse);
        expect(cubit.state.user, isNull);
      },
    );
  });
}

