import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scp_mobile_shared/models/message_model.dart';
import 'package:scp_mobile_shared/services/chat_service.dart';

/// Chat State
class ChatState extends Equatable {
  const ChatState({
    this.conversations = const [],
    this.messages = const {},
    this.selectedConversationId,
    this.isLoading = false,
    this.error,
  });

  final List<ConversationModel> conversations;
  final Map<String, List<MessageModel>> messages; // conversationId -> messages
  final String? selectedConversationId;
  final bool isLoading;
  final String? error;

  List<MessageModel> get currentMessages {
    if (selectedConversationId == null) return [];
    return messages[selectedConversationId] ?? [];
  }

  ChatState copyWith({
    List<ConversationModel>? conversations,
    Map<String, List<MessageModel>>? messages,
    String? selectedConversationId,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      selectedConversationId: selectedConversationId ?? this.selectedConversationId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        messages,
        selectedConversationId,
        isLoading,
        error,
      ];
}

/// Chat Cubit
class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;

  ChatCubit({ChatService? chatService})
      : _chatService = chatService ?? ChatService(),
        super(const ChatState());

  /// Load conversations
  Future<void> loadConversations() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final conversations = await _chatService.getConversations();
      emit(state.copyWith(
        conversations: conversations,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Load messages for a conversation
  Future<void> loadMessages(String conversationId) async {
    emit(state.copyWith(isLoading: true, error: null, selectedConversationId: conversationId));

    try {
      final messagesList = await _chatService.getMessages(conversationId);
      final updatedMessages = Map<String, List<MessageModel>>.from(state.messages);
      updatedMessages[conversationId] = messagesList;

      emit(state.copyWith(
        messages: updatedMessages,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Send text message
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? orderId,
  }) async {
    try {
      final message = await _chatService.sendMessage(
        conversationId: conversationId,
        content: content,
        orderId: orderId,
      );

      // Add message to state
      final updatedMessages = Map<String, List<MessageModel>>.from(state.messages);
      if (!updatedMessages.containsKey(conversationId)) {
        updatedMessages[conversationId] = [];
      }
      updatedMessages[conversationId]!.add(message);

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Send image
  Future<void> sendImage({
    required String conversationId,
    required File imageFile,
    String? orderId,
  }) async {
    try {
      final message = await _chatService.sendImage(
        conversationId: conversationId,
        imageFile: imageFile,
        orderId: orderId,
      );

      final updatedMessages = Map<String, List<MessageModel>>.from(state.messages);
      if (!updatedMessages.containsKey(conversationId)) {
        updatedMessages[conversationId] = [];
      }
      updatedMessages[conversationId]!.add(message);

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Send file
  Future<void> sendFile({
    required String conversationId,
    required File file,
    String? orderId,
  }) async {
    try {
      final message = await _chatService.sendFile(
        conversationId: conversationId,
        file: file,
        orderId: orderId,
      );

      final updatedMessages = Map<String, List<MessageModel>>.from(state.messages);
      if (!updatedMessages.containsKey(conversationId)) {
        updatedMessages[conversationId] = [];
      }
      updatedMessages[conversationId]!.add(message);

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Start conversation
  Future<String?> startConversation({
    required String supplierId,
    String? orderId,
  }) async {
    try {
      final conversation = await _chatService.startConversation(
        supplierId: supplierId,
        orderId: orderId,
      );

      // Add to conversations
      final updatedConversations = [...state.conversations];
      if (!updatedConversations.any((c) => c.id == conversation.id)) {
        updatedConversations.add(conversation);
      }

      emit(state.copyWith(
        conversations: updatedConversations,
        selectedConversationId: conversation.id,
      ));

      return conversation.id;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return null;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _chatService.markMessagesAsRead(conversationId);
      // Update state
      final updatedConversations = state.conversations.map((c) {
        if (c.id == conversationId) {
          return ConversationModel(
            id: c.id,
            supplierId: c.supplierId,
            supplierName: c.supplierName,
            supplierLogoUrl: c.supplierLogoUrl,
            lastMessage: c.lastMessage,
            lastMessageTime: c.lastMessageTime,
            unreadCount: 0,
            orderId: c.orderId,
            createdAt: c.createdAt,
          );
        }
        return c;
      }).toList();

      emit(state.copyWith(conversations: updatedConversations));
    } catch (e) {
      // Handle silently
    }
  }

  /// Start complaint thread
  Future<String?> startComplaintThread(String orderId) async {
    try {
      final conversation = await _chatService.startComplaintThread(orderId);

      final updatedConversations = [...state.conversations];
      if (!updatedConversations.any((c) => c.id == conversation.id)) {
        updatedConversations.add(conversation);
      }

      emit(state.copyWith(
        conversations: updatedConversations,
        selectedConversationId: conversation.id,
      ));

      return conversation.id;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return null;
    }
  }

  /// Clear selected conversation
  void clearSelection() {
    emit(state.copyWith(selectedConversationId: null));
  }
}

