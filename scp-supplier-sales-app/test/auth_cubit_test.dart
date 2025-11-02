import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:scp_supplier_sales_app/cubits/auth_cubit.dart';

void main() {
  group('AuthCubit (Supplier)', () {
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
    });

    // Additional tests would require mocked AuthService
    // Similar structure to consumer app tests
  });
}

