import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/chat_sales_cubit.dart';
import '../../cubits/auth_cubit.dart';
import 'package:scp_mobile_shared/models/message_model.dart';
import 'package:scp_mobile_shared/config/app_theme_supplier.dart';

/// Enhanced chat screen for supplier sales reps with canned replies
class SupplierChatScreen extends StatefulWidget {
  final String conversationId;
  final String consumerName;
  final String? consumerAvatarUrl;
  final String? orderId;

  const SupplierChatScreen({
    super.key,
    required this.conversationId,
    required this.consumerName,
    this.consumerAvatarUrl,
    this.orderId,
  });

  @override
  State<SupplierChatScreen> createState() => _SupplierChatScreenState();
}

class _SupplierChatScreenState extends State<SupplierChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showCannedReplies = false;

  @override
  void initState() {
    super.initState();
    context.read<ChatSalesCubit>().loadMessages(widget.conversationId);
    context.read<ChatSalesCubit>().markAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatSalesCubit>().sendMessage(
            conversationId: widget.conversationId,
            content: message,
            orderId: widget.orderId,
          );
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _useCannedReply(String content) {
    _messageController.text = content;
    setState(() {
      _showCannedReplies = false;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      context.read<ChatSalesCubit>().sendImage(
            conversationId: widget.conversationId,
            imageFile: File(image.path),
            orderId: widget.orderId,
          );
    }
  }

  bool _isCurrentUser(String senderId) {
    final authState = context.read<AuthCubit>().state;
    return authState.user?.id == senderId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<ChatSalesCubit>().clearSelection();
            Navigator.pop(context);
          },
        ),
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: widget.consumerAvatarUrl != null
                ? NetworkImage(widget.consumerAvatarUrl!)
                : null,
            child: widget.consumerAvatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(widget.consumerName),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined),
            onPressed: () {
              // Show escalate complaint dialog
            },
            tooltip: 'Escalate to Manager',
          ),
        ],
      ),
      body: Column(
        children: [
          // Canned replies bar
          if (_showCannedReplies) _buildCannedRepliesBar(),
          
          // Messages
          Expanded(
            child: BlocBuilder<ChatSalesCubit, ChatSalesState>(
              builder: (context, state) {
                final messages = state.currentMessages;

                if (state.isLoading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[messages.length - 1 - index];
                          final isCurrentUser = _isCurrentUser(message.senderId);
                          
                          return Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? AppThemeSupplier.primaryColor
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message.type == MessageType.image &&
                                      message.fileUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        message.fileUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  if (message.type == MessageType.file &&
                                      message.fileName != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_file),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(message.fileName!),
                                        ),
                                      ],
                                    ),
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isCurrentUser
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
          // Message input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_quote),
                      onPressed: () {
                        setState(() {
                          _showCannedReplies = !_showCannedReplies;
                        });
                      },
                      tooltip: 'Canned Replies',
                    ),
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCannedRepliesBar() {
    // Placeholder for canned replies
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        children: [
          _buildCannedReplyChip('Thank you for your message!'),
          _buildCannedReplyChip('I will check on this for you.'),
          _buildCannedReplyChip('Your order is being processed.'),
          _buildCannedReplyChip('We apologize for the inconvenience.'),
        ],
      ),
    );
  }

  Widget _buildCannedReplyChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: () => _useCannedReply(text),
        backgroundColor: AppThemeSupplier.primaryColor.withOpacity(0.1),
        labelStyle: TextStyle(color: AppThemeSupplier.primaryColor),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

