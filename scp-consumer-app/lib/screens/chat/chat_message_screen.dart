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
import '../../cubits/chat_cubit.dart';
import '../../cubits/auth_cubit.dart';
import 'package:scp_mobile_shared/widgets/loading_indicator.dart';
import 'package:scp_mobile_shared/models/message_model.dart';
import 'package:scp_mobile_shared/config/app_config.dart';

/// Chat message screen
class ChatMessageScreen extends StatefulWidget {
  final String conversationId;
  final String supplierName;
  final String? supplierLogoUrl;

  const ChatMessageScreen({
    super.key,
    required this.conversationId,
    required this.supplierName,
    this.supplierLogoUrl,
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
    // Set selected conversation ID before loading messages
    final cubit = context.read<ChatCubit>();
    if (cubit.state.selectedConversationId != widget.conversationId) {
      cubit.emit(cubit.state.copyWith(selectedConversationId: widget.conversationId));
    }
    cubit.loadMessages(widget.conversationId);
    cubit.markAsRead(widget.conversationId);
    // Scroll to bottom after initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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
      context.read<ChatCubit>().sendMessage(
            conversationId: widget.conversationId,
            content: message,
          );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      context.read<ChatCubit>().sendImage(
            conversationId: widget.conversationId,
            imageFile: File(image.path),
          );
      _scrollToBottom();
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      
      if (result != null && result.files.single.path != null && mounted) {
        context.read<ChatCubit>().sendFile(
              conversationId: widget.conversationId,
              file: File(result.files.single.path!),
            );
        _scrollToBottom();
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
        context.read<ChatCubit>().sendFile(
              conversationId: widget.conversationId,
              file: File(path),
            );
        _scrollToBottom();
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
            context.read<ChatCubit>().clearSelection();
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
      ),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          final messages = state.currentMessages;

          if (state.isLoading && messages.isEmpty) {
            return const LoadingIndicator();
          }

          // Scroll to bottom when messages change
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
                          final message = messages[index];
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
                                    Image.network(
                                      message.fileUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  if (message.type == MessageType.file &&
                                      message.fileName != null &&
                                      message.type != MessageType.audio)
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
    // Convert UTC to local time for display
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);
    
    if (messageDate == today) {
      // Today - show time only
      return '${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Older - show date and time
      return '${localTime.day}/${localTime.month} ${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}';
    }
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

