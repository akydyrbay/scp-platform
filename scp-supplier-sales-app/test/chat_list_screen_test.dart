import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scp_supplier_sales_app/cubits/chat_sales_cubit.dart';
import 'package:scp_supplier_sales_app/screens/chat/chat_list_screen.dart';

void main() {
  group('ChatListScreen Widget Tests', () {
    testWidgets('displays chat list screen', (WidgetTester tester) async {
      final chatCubit = ChatSalesCubit();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: chatCubit,
            child: const ChatListScreen(),
          ),
        ),
      );

      expect(find.byType(ChatListScreen), findsOneWidget);
      
      chatCubit.close();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}

