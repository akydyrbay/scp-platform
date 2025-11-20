import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scp_mobile_shared/models/message_model.dart';
import 'package:scp_mobile_shared/services/chat_service_sales.dart';
import 'package:scp_mobile_shared/models/conversation_model.dart';

/// Chat State for Sales
class ChatSalesState extends Equatable {
  const ChatSalesState({
    this.conversations = const [],
    this.messages = const {},
    this.selectedConversationId,
    this.isLoading = false,
    this.error,
  });

  final List<ConversationModelSales> conversations;
  final Map<String, List<MessageModel>> messages; // conversationId -> messages
  final String? selectedConversationId;
  final bool isLoading;
  final String? error;

  List<MessageModel> get currentMessages {
    if (selectedConversationId == null) return [];
    return messages[selectedConversationId] ?? [];
  }

  ChatSalesState copyWith({
    List<ConversationModelSales>? conversations,
    Map<String, List<MessageModel>>? messages,
    String? selectedConversationId,
    bool? isLoading,
    String? error,
    bool clearSelectedConversationId = false,
  }) {
    return ChatSalesState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      selectedConversationId: clearSelectedConversationId 
          ? null 
          : (selectedConversationId ?? this.selectedConversationId),
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

/// Chat Cubit for Sales
class ChatSalesCubit extends Cubit<ChatSalesState> {
  final ChatServiceSales _chatService;

  ChatSalesCubit({ChatServiceSales? chatService})
      : _chatService = chatService ?? ChatServiceSales(),
        super(const ChatSalesState());

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
    emit(state.copyWith(
      isLoading: true,
      error: null,
      selectedConversationId: conversationId,
    ));

    try {
      final messagesList = await _chatService.getMessages(conversationId);
      final updatedMessages = Map<String, List<MessageModel>>.from(state.messages);
      // Backend returns messages in DESC order (newest first)
      // Reverse to ASC order (oldest first) so that with ListView reverse:true,
      // newest messages appear at bottom
      messagesList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      updatedMessages[conversationId] = messagesList;

      emit(state.copyWith(
        messages: updatedMessages,
        selectedConversationId: conversationId,
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
      await _chatService.sendMessage(
        conversationId: conversationId,
        content: content,
        orderId: orderId,
      );

      // Reload messages to ensure we have the latest from server
      // This ensures consistency and gets any messages we might have missed
      final messagesList = await _chatService.getMessages(conversationId);
      
      // Update state with all messages
      final updatedMessages = Map<String, List<MessageModel>>.from(state.messages);
      // Sort by timestamp ASC (oldest first) so newest appears at bottom with reverse:true
      messagesList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      updatedMessages[conversationId] = messagesList;

      emit(state.copyWith(
        messages: updatedMessages,
        selectedConversationId: conversationId,
        error: null,
      ));
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
      await _chatService.sendImage(
        conversationId: conversationId,
        imageFile: imageFile,
        orderId: orderId,
      );

      // Reload messages to ensure we have the latest from server
      final messagesList = await _chatService.getMessages(conversationId);
      
      final updatedMessages = Map<String, List<MessageModel>>.from(state.messages);
      // Sort by timestamp ASC (oldest first) so newest appears at bottom with reverse:true
      messagesList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      updatedMessages[conversationId] = messagesList;

      emit(state.copyWith(
        messages: updatedMessages,
        selectedConversationId: conversationId,
        error: null,
      ));
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
      await _chatService.sendFile(
        conversationId: conversationId,
        file: file,
        orderId: orderId,
      );

      // Reload messages to ensure we have the latest from server
      final messagesList = await _chatService.getMessages(conversationId);
      
      final updatedMessages = Map<String, List<MessageModel>>.from(state.messages);
      // Sort by timestamp ASC (oldest first) so newest appears at bottom with reverse:true
      messagesList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      updatedMessages[conversationId] = messagesList;

      emit(state.copyWith(
        messages: updatedMessages,
        selectedConversationId: conversationId,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _chatService.markMessagesAsRead(conversationId);
    } catch (e) {
      // Handle silently
    }
  }

  /// Clear selected conversation
  void clearSelection() {
    emit(state.copyWith(clearSelectedConversationId: true));
  }
}

