import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:scp_mobile_shared/models/message_model.dart';
import 'package:scp_mobile_shared/services/chat_service.dart';
import 'package:scp_mobile_shared/services/http_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import '../lib/cubits/chat_cubit.dart';

class MockChatService extends Mock implements ChatService {}
class MockHttpService extends Mock implements HttpService {}

void main() {
  group('ChatCubit', () {
    late ChatCubit chatCubit;
    late MockChatService mockChatService;

    setUp(() {
      mockChatService = MockChatService();
      chatCubit = ChatCubit(chatService: mockChatService);
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

    blocTest<ChatCubit, ChatState>(
      'loadConversations emits loading then success with conversations',
      build: () {
        when(() => mockChatService.getConversations()).thenAnswer(
          (_) async => [
            ConversationModel(
              id: 'conv1',
              supplierId: 'supplier1',
              supplierName: 'Test Supplier',
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
        ChatState(isLoading: true, error: null),
        predicate<ChatState>((state) =>
          state.isLoading == false &&
          state.conversations.length == 1 &&
          state.conversations.first.id == 'conv1' &&
          state.conversations.first.supplierId == 'supplier1' &&
          state.conversations.first.supplierName == 'Test Supplier' &&
          state.conversations.first.lastMessage == 'Hello' &&
          state.conversations.first.unreadCount == 2),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'loadConversations handles errors correctly',
      build: () {
        when(() => mockChatService.getConversations()).thenThrow(
          Exception('Network error'),
        );
        return chatCubit;
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        ChatState(isLoading: true, error: null),
        ChatState(
          isLoading: false,
          error: 'Exception: Network error',
        ),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'loadMessages loads messages for a conversation',
      build: () {
        when(() => mockChatService.getMessages('conv1')).thenAnswer(
          (_) async => [
            MessageModel(
              id: 'msg1',
              conversationId: 'conv1',
              senderId: 'consumer1',
              senderName: 'Test User',
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
        ChatState(
          isLoading: true,
          error: null,
          selectedConversationId: 'conv1',
        ),
        predicate<ChatState>((state) =>
          state.isLoading == false &&
          state.selectedConversationId == 'conv1' &&
          state.messages.containsKey('conv1') &&
          state.messages['conv1']!.length == 1 &&
          state.messages['conv1']!.first.id == 'msg1' &&
          state.messages['conv1']!.first.content == 'Hello'),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'sendMessage adds message to state',
      build: () {
        when(() => mockChatService.sendMessage(
          conversationId: 'conv1',
          content: 'Test message',
        )).thenAnswer(
          (_) async => MessageModel(
            id: 'msg2',
            conversationId: 'conv1',
            senderId: 'consumer1',
            senderName: 'Test User',
            content: 'Test message',
            type: MessageType.text,
            timestamp: DateTime.now(),
            isRead: false,
          ),
        );
        return chatCubit;
      },
      seed: () => ChatState(
        messages: {
          'conv1': [
            MessageModel(
              id: 'msg1',
              conversationId: 'conv1',
              senderId: 'consumer1',
              senderName: 'Test User',
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
      verify: (cubit) {
        expect(cubit.state.messages.containsKey('conv1'), true);
        expect(cubit.state.messages['conv1']!.length, 2);
        expect(cubit.state.messages['conv1']!.any((m) => m.id == 'msg1' && m.content == 'Hello'), true);
        expect(cubit.state.messages['conv1']!.any((m) => m.id == 'msg2' && m.content == 'Test message'), true);
      },
    );
  });
}

