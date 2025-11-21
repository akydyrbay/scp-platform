import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../cubits/auth_cubit.dart';
import '../../cubits/chat_sales_cubit.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/models/message_model.dart';
import 'package:scp_mobile_shared/config/app_config.dart';
import '../supplier_chat/complaint_log_screen.dart';

/// Chat message screen
class ChatMessageScreen extends StatefulWidget {
  final String conversationId;
  final String supplierName;
  final String? supplierLogoUrl;
  final String consumerId;
  final String? orderId;
  final String? orderNumber;

  const ChatMessageScreen({
    super.key,
    required this.conversationId,
    required this.supplierName,
    this.supplierLogoUrl,
    required this.consumerId,
    this.orderId,
    this.orderNumber,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    // Load messages if not already loaded
    final cubit = context.read<ChatSalesCubit>();
    if (cubit.state.selectedConversationId != widget.conversationId) {
      cubit.loadMessages(widget.conversationId);
    }
    cubit.markAsRead(widget.conversationId);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatSalesCubit>().sendMessage(
            conversationId: widget.conversationId,
            content: message,
          );
      _messageController.clear();
      // Scroll to bottom after sending - wait for message to be added
      Future.delayed(const Duration(milliseconds: 500), () {
        _scrollToBottom();
      });
    }
  }


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      context.read<ChatSalesCubit>().sendImage(
            conversationId: widget.conversationId,
            imageFile: File(image.path),
          );
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      
      if (result != null && result.files.single.path != null && mounted) {
        context.read<ChatSalesCubit>().sendFile(
              conversationId: widget.conversationId,
              file: File(result.files.single.path!),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check if running on web - recording not supported
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio recording is not supported on web')),
          );
        }
        return;
      }

      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to record audio')),
          );
        }
        return;
      }

      // Check if recorder has permission
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        try {
          await _audioRecorder.start(
            RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: path,
          );
          
          setState(() {
            _isRecording = true;
          });
        } catch (recordError) {
          // Handle MissingPluginException
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Audio recording not available: $recordError')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording({bool send = true}) async {
    try {
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });

      if (send && path != null && mounted) {
        context.read<ChatSalesCubit>().sendFile(
              conversationId: widget.conversationId,
              file: File(path),
            );
      } else if (path != null) {
        // Delete the recording if not sending
        try {
          await File(path).delete();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<void> _playAudio(String messageId, String audioUrl) async {
    try {
      // Check if running on web - audio playback may not work
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio playback is not supported on web')),
          );
        }
        return;
      }

      if (_playingMessageId == messageId) {
        // Stop if already playing
        try {
          await _audioPlayer.stop();
        } catch (e) {
          // Ignore errors when stopping
        }
        setState(() {
          _playingMessageId = null;
        });
      } else {
        // Stop any currently playing audio
        if (_playingMessageId != null) {
          try {
            await _audioPlayer.stop();
          } catch (e) {
            // Ignore errors when stopping
          }
        }
        
        // Construct full URL if relative
        String fullUrl = audioUrl;
        if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
          // Use base URL from config
          fullUrl = AppConfig.baseUrl + (audioUrl.startsWith('/') ? audioUrl : '/$audioUrl');
        }
        
        // Play new audio with error handling
        try {
          await _audioPlayer.play(UrlSource(fullUrl));
          setState(() {
            _playingMessageId = messageId;
          });

          // Reset when playback completes
          _audioPlayer.onPlayerComplete.listen((_) {
            if (mounted) {
              setState(() {
                _playingMessageId = null;
              });
            }
          });
        } catch (playError) {
          // Handle MissingPluginException or other playback errors
          if (mounted) {
            setState(() {
              _playingMessageId = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Audio playback not available: $playError')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _playingMessageId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
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
            backgroundImage: widget.supplierLogoUrl != null
                ? NetworkImage(widget.supplierLogoUrl!)
                : null,
            child: widget.supplierLogoUrl == null
                ? const Icon(Icons.business)
                : null,
          ),
          title: Text(widget.supplierName),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.warning_amber_outlined),
            label: const Text('Escalate'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final didSubmit = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => ComplaintLogScreen(
                    consumerName: widget.supplierName,
                    consumerId: widget.consumerId,
                    orderId: widget.orderId,
                    orderNumber: widget.orderNumber,
                    conversationId: widget.conversationId,
                  ),
                ),
              );

              if (didSubmit == true && mounted) {
                // Reload messages so the escalation chat message from backend appears
                await context
                    .read<ChatSalesCubit>()
                    .loadMessages(widget.conversationId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Issue escalated to manager. Escalation note added to chat.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatSalesCubit, ChatSalesState>(
        builder: (context, state) {
          final messages = state.currentMessages;

          if (state.isLoading && messages.isEmpty) {
            return const LoadingIndicator();
          }

          // Scroll to bottom when messages load or update
          if (messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }

          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          // Messages are sorted ASC (oldest first), so with reverse:true,
                          // index 0 (oldest) shows at top, last index (newest) shows at bottom
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
                                    ? Theme.of(context).primaryColor
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
                                        height: 200,
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
                                  if (message.type == MessageType.audio &&
                                      message.fileUrl != null)
                                    _buildAudioPlayer(message.id, message.fileUrl!),
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
                      ),
              ),
              // Message input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
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
                          icon: const Icon(Icons.attach_file),
                          onPressed: _pickFile,
                        ),
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: _pickImage,
                        ),
                        IconButton(
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          color: _isRecording ? Colors.red : null,
                          onPressed: _isRecording
                              ? () => _stopRecording(send: true)
                              : _startRecording,
                          onLongPress: _isRecording
                              ? () => _stopRecording(send: false)
                              : null,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(24),
                                ),
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
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAudioPlayer(String messageId, String audioUrl) {
    final isPlaying = _playingMessageId == messageId;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () => _playAudio(messageId, audioUrl),
          ),
          const SizedBox(width: 8),
          const Text('Audio message'),
        ],
      ),
    );
  }
}

