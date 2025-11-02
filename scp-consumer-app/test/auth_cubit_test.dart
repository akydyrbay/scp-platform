import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:scp_consumer_app/cubits/auth_cubit.dart';

void main() {
  group('AuthCubit', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit();
    });

    tearDown(() {
      authCubit.close();
    });

    test('initial state is not authenticated', () {
      expect(authCubit.state.isAuthenticated, isFalse);
      expect(authCubit.state.isLoading, isFalse);
      expect(authCubit.state.user, isNull);
      expect(authCubit.state.error, isNull);
    });

    blocTest<AuthCubit, AuthState>(
      'logout emits unauthenticated state',
      build: () => AuthCubit(),
      wait: const Duration(milliseconds: 300), // Wait for _checkAuthStatus to complete
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

