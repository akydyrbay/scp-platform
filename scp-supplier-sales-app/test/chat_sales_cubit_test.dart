import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:scp_mobile_shared/models/message_model.dart';
import 'package:scp_mobile_shared/models/conversation_model.dart';
import 'package:scp_mobile_shared/services/chat_service_sales.dart';
import 'package:mocktail/mocktail.dart';
import '../lib/cubits/chat_sales_cubit.dart';

class MockChatServiceSales extends Mock implements ChatServiceSales {}

void main() {
  group('ChatSalesCubit', () {
    late ChatSalesCubit chatCubit;
    late MockChatServiceSales mockChatService;

    setUp(() {
      mockChatService = MockChatServiceSales();
      chatCubit = ChatSalesCubit(chatService: mockChatService);
    });

    tearDown(() {
      chatCubit.close();
    });

    test('initial state is correct', () {
      expect(chatCubit.state.conversations, isEmpty);
      expect(chatCubit.state.messages, isEmpty);
      expect(chatCubit.state.isLoading, false);
      expect(chatCubit.state.error, isNull);
    });

    blocTest<ChatSalesCubit, ChatSalesState>(
      'loadConversations emits loading then success with conversations',
      build: () {
        when(() => mockChatService.getConversations()).thenAnswer(
          (_) async => [
            ConversationModelSales(
              id: 'conv1',
              consumerId: 'consumer1',
              consumerName: 'Test Consumer',
              lastMessage: 'Hello',
              lastMessageTime: DateTime.now(),
              unreadCount: 2,
              createdAt: DateTime.now(),
            ),
          ],
        );
        return chatCubit;
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        ChatSalesState(isLoading: true, error: null),
        predicate<ChatSalesState>((state) =>
          state.isLoading == false &&
          state.conversations.length == 1 &&
          state.conversations.first.id == 'conv1' &&
          state.conversations.first.consumerId == 'consumer1' &&
          state.conversations.first.consumerName == 'Test Consumer' &&
          state.conversations.first.lastMessage == 'Hello' &&
          state.conversations.first.unreadCount == 2),
      ],
    );

    blocTest<ChatSalesCubit, ChatSalesState>(
      'loadConversations handles errors correctly',
      build: () {
        when(() => mockChatService.getConversations()).thenThrow(
          Exception('Network error'),
        );
        return chatCubit;
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        ChatSalesState(isLoading: true, error: null),
        ChatSalesState(
          isLoading: false,
          error: 'Exception: Network error',
        ),
      ],
    );

    blocTest<ChatSalesCubit, ChatSalesState>(
      'loadMessages loads messages for a conversation',
      build: () {
        when(() => mockChatService.getMessages('conv1')).thenAnswer(
          (_) async => [
            MessageModel(
              id: 'msg1',
              conversationId: 'conv1',
              senderId: 'consumer1',
              senderName: 'Test Consumer',
              content: 'Hello',
              type: MessageType.text,
              timestamp: DateTime.now(),
              isRead: false,
            ),
          ],
        );
        return chatCubit;
      },
      act: (cubit) => cubit.loadMessages('conv1'),
      expect: () => [
        ChatSalesState(
          isLoading: true,
          error: null,
          selectedConversationId: 'conv1',
        ),
        predicate<ChatSalesState>((state) =>
          state.isLoading == false &&
          state.selectedConversationId == 'conv1' &&
          state.messages.containsKey('conv1') &&
          state.messages['conv1']!.length == 1 &&
          state.messages['conv1']!.first.id == 'msg1' &&
          state.messages['conv1']!.first.content == 'Hello'),
      ],
    );
  });
}

