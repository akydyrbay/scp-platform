import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/chat_cubit.dart';
import '../../cubits/supplier_cubit.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/widgets/error_widget.dart';
import 'package:scp_mobile_shared/widgets/empty_state_widget.dart';
import 'package:scp_mobile_shared/models/supplier_model.dart';
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
    // Load linked suppliers for starting new chats
    context.read<SupplierCubit>().loadLinkedSuppliers();
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

  Future<void> _showStartChatDialog(BuildContext context) async {
    // Load linked suppliers if not already loaded
    final supplierState = context.read<SupplierCubit>().state;
    if (supplierState.linkedSuppliers.isEmpty) {
      await context.read<SupplierCubit>().loadLinkedSuppliers();
    }

    final updatedState = context.read<SupplierCubit>().state;
    if (updatedState.linkedSuppliers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No linked suppliers available. Please link with a supplier first.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return BlocBuilder<SupplierCubit, SupplierState>(
          builder: (context, state) {
            if (state.linkedSuppliers.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text('No linked suppliers available'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: state.linkedSuppliers.length,
              itemBuilder: (context, index) {
                final supplier = state.linkedSuppliers[index];
                return ListTile(
                  leading: supplier.logoUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(supplier.logoUrl!),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.business),
                        ),
                  title: Text(supplier.companyName),
                  subtitle: supplier.description != null
                      ? Text(
                          supplier.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await _startConversation(context, supplier);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _startConversation(BuildContext context, SupplierModel supplier) async {
    try {
      final conversationId = await context.read<ChatCubit>().startConversation(
            supplierId: supplier.id,
          );

      if (conversationId != null && mounted) {
        // Reload conversations to get the new one
        await context.read<ChatCubit>().loadConversations();
        
        // Load messages and navigate to chat screen
        context.read<ChatCubit>().loadMessages(conversationId);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatMessageScreen(
                conversationId: conversationId,
                supplierName: supplier.companyName,
                supplierLogoUrl: supplier.logoUrl,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start conversation'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => _showStartChatDialog(context),
            tooltip: 'Start new chat',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStartChatDialog(context),
        child: const Icon(Icons.add_comment),
        tooltip: 'Start new chat',
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

