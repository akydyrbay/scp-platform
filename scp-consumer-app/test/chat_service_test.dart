import 'package:flutter_test/flutter_test.dart';
import 'package:scp_mobile_shared/services/chat_service.dart';
import 'package:scp_mobile_shared/services/http_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

class MockHttpService extends Mock implements HttpService {}

void main() {
  group('ChatService', () {
    late ChatService chatService;
    late MockHttpService mockHttpService;

    setUp(() {
      mockHttpService = MockHttpService();
      chatService = ChatService(httpService: mockHttpService);
    });

    test('getConversations handles paginated response format', () async {
      when(() => mockHttpService.get('/consumer/conversations')).thenAnswer(
        (_) async => Response(
          data: {
            'results': [
              {
                'id': 'conv1',
                'supplier_id': 'supplier1',
                'supplier_name': 'Test Supplier',
                'last_message': 'Hello',
                'last_message_time': DateTime.now().toIso8601String(),
                'unread_count': 2,
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/consumer/conversations'),
        ),
      );

      final conversations = await chatService.getConversations();
      expect(conversations.length, 1);
      expect(conversations.first.id, 'conv1');
    });

    test('getConversations handles wrapped data format', () async {
      when(() => mockHttpService.get('/consumer/conversations')).thenAnswer(
        (_) async => Response(
          data: {
            'data': [
              {
                'id': 'conv1',
                'supplier_id': 'supplier1',
                'supplier_name': 'Test Supplier',
                'last_message': 'Hello',
                'last_message_time': DateTime.now().toIso8601String(),
                'unread_count': 2,
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/consumer/conversations'),
        ),
      );

      final conversations = await chatService.getConversations();
      expect(conversations.length, 1);
      expect(conversations.first.id, 'conv1');
    });

    test('getMessages handles paginated response format', () async {
      when(() => mockHttpService.get(
        '/consumer/conversations/conv1/messages',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer(
        (_) async => Response(
          data: {
            'results': [
              {
                'id': 'msg1',
                'conversation_id': 'conv1',
                'sender_id': 'consumer1',
                'sender_name': 'Test User',
                'content': 'Hello',
                'type': 'text',
                'timestamp': DateTime.now().toIso8601String(),
                'is_read': false,
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/consumer/conversations/conv1/messages'),
        ),
      );

      final messages = await chatService.getMessages('conv1');
      expect(messages.length, 1);
      expect(messages.first.content, 'Hello');
    });

    test('sendMessage handles wrapped response format', () async {
      when(() => mockHttpService.post(
        '/consumer/conversations/conv1/messages',
        data: any(named: 'data'),
      )).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'id': 'msg1',
              'conversation_id': 'conv1',
              'sender_id': 'consumer1',
              'sender_name': 'Test User',
              'content': 'Test message',
              'type': 'text',
              'timestamp': DateTime.now().toIso8601String(),
              'is_read': false,
            },
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/consumer/conversations/conv1/messages'),
        ),
      );

      final message = await chatService.sendMessage(
        conversationId: 'conv1',
        content: 'Test message',
      );
      expect(message.content, 'Test message');
    });

    test('getConversations handles errors correctly', () async {
      when(() => mockHttpService.get('/consumer/conversations')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/consumer/conversations'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/consumer/conversations'),
          ),
        ),
      );

      expect(
        () => chatService.getConversations(),
        throwsA(isA<Exception>()),
      );
    });
  });
}

