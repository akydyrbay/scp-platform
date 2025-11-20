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

    blocTest<ChatSalesCubit, ChatSalesState>(
      'sendMessage adds message to state',
      build: () {
        when(() => mockChatService.sendMessage(
          conversationId: 'conv1',
          content: 'Test message',
          orderId: null,
        )).thenAnswer((_) async => MessageModel(
          id: 'msg2',
          conversationId: 'conv1',
          senderId: 'sales1',
          senderName: 'Sales Rep',
          content: 'Test message',
          type: MessageType.text,
          timestamp: DateTime.now(),
          isRead: true,
        ));
        return chatCubit;
      },
      seed: () => ChatSalesState(
        conversations: [],
        messages: {
          'conv1': [
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
        },
      ),
      act: (cubit) => cubit.sendMessage(
        conversationId: 'conv1',
        content: 'Test message',
      ),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        predicate<ChatSalesState>((state) =>
          state.messages.containsKey('conv1') &&
          state.messages['conv1']!.length == 2 &&
          state.messages['conv1']!.last.content == 'Test message'),
      ],
    );

    blocTest<ChatSalesCubit, ChatSalesState>(
      'sendMessage handles errors correctly',
      build: () {
        when(() => mockChatService.sendMessage(
          conversationId: 'conv1',
          content: 'Test message',
          orderId: null,
        )).thenThrow(Exception('Failed to send'));
        return chatCubit;
      },
      act: (cubit) => cubit.sendMessage(
        conversationId: 'conv1',
        content: 'Test message',
      ),
      expect: () => [
        predicate<ChatSalesState>((state) =>
          state.error != null &&
          state.error!.contains('Failed to send')),
      ],
    );

    blocTest<ChatSalesCubit, ChatSalesState>(
      'markAsRead calls service',
      build: () {
        when(() => mockChatService.markMessagesAsRead('conv1')).thenAnswer(
          (_) async => {},
        );
        return chatCubit;
      },
      act: (cubit) => cubit.markAsRead('conv1'),
      verify: (_) {
        verify(() => mockChatService.markMessagesAsRead('conv1')).called(1);
      },
    );

    blocTest<ChatSalesCubit, ChatSalesState>(
      'clearSelection clears selected conversation',
      build: () => chatCubit,
      seed: () => ChatSalesState(
        selectedConversationId: 'conv1',
        conversations: [],
        messages: {},
      ),
      act: (cubit) => cubit.clearSelection(),
      expect: () => [
        ChatSalesState(
          selectedConversationId: null,
          conversations: [],
          messages: {},
        ),
      ],
    );
  });
}

