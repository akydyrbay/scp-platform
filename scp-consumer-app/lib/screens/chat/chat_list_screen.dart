import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/chat_cubit.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/widgets/error_widget.dart';
import 'package:scp_mobile_shared/widgets/empty_state_widget.dart';
import 'chat_message_screen.dart';

/// Chat list screen
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadConversations();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          if (state.isLoading && state.conversations.isEmpty) {
            return const LoadingIndicator();
          }

          if (state.error != null && state.conversations.isEmpty) {
            return ErrorDisplay(
              message: state.error!,
              onRetry: () => context.read<ChatCubit>().loadConversations(),
            );
          }

          if (state.conversations.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'No messages',
              subtitle: 'Start a conversation with a supplier',
            );
          }

          return ListView.builder(
            itemCount: state.conversations.length,
            itemBuilder: (context, index) {
              final conversation = state.conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: conversation.supplierLogoUrl != null
                      ? NetworkImage(conversation.supplierLogoUrl!)
                      : null,
                  child: conversation.supplierLogoUrl == null
                      ? const Icon(Icons.business)
                      : null,
                ),
                title: Text(
                  conversation.supplierName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  conversation.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (conversation.lastMessageTime != null)
                      Text(
                        _formatTime(conversation.lastMessageTime!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (conversation.unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          conversation.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  // Load messages first, then navigate
                  context.read<ChatCubit>().loadMessages(conversation.id);
                  // Navigate to chat message screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatMessageScreen(
                        conversationId: conversation.id,
                        supplierName: conversation.supplierName,
                        supplierLogoUrl: conversation.supplierLogoUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

