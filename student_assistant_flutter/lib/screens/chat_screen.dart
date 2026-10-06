import 'package:flutter/material.dart';
import '../services/chat_service.dart';

/// Màn hình Chat AI
/// Giao diện đơn giản giống ứng dụng chat
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Service để gọi API
  final ChatService _chatService = ChatService();
  
  // Controller cho TextField
  final TextEditingController _messageController = TextEditingController();
  
  // ScrollController để scroll xuống message mới nhất
  final ScrollController _scrollController = ScrollController();
  
  // Danh sách tin nhắn (lưu tạm trong session)
  List<Map<String, String>> _messages = [];
  
  // Trạng thái đang gửi
  bool _isSending = false;
  
  // Trạng thái đang load lịch sử
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Tải lịch sử chat từ backend
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final history = await _chatService.getMessages();
      setState(() {
        _messages = history.map((msg) => {
          'user': msg.message,
          'ai': msg.response,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Gửi tin nhắn tới AI thật
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    
    // Không gửi message rỗng
    if (content.isEmpty || _isSending) return;

    // Clear TextField ngay sau khi lấy content
    _messageController.clear();
    
    // Disable Send button
    setState(() => _isSending = true);

    // Thêm message của user vào danh sách (với response rỗng để hiển thị loading)
    setState(() {
      _messages.add({'user': content, 'ai': ''});
    });

    // Scroll xuống message mới nhất
    _scrollToBottom();
    
    try {
      // Gọi API AI thật qua backend -> Gemini
      final result = await _chatService.askAI(content);
      
      // Cập nhật AI response thật
      setState(() {
        _messages[_messages.length - 1]['ai'] = result.response;
        _isSending = false;
      });
    } catch (e) {
      // Xử lý lỗi - hiển thị SnackBar và không crash app
      setState(() {
        _messages[_messages.length - 1]['ai'] = '❌ Lỗi: ${e.toString().replaceAll('Exception: ', '')}';
        _isSending = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi AI: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // Scroll xuống message mới nhất sau khi có response
    _scrollToBottom();
  }

  /// Scroll xuống cuối danh sách
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Xóa toàn bộ lịch sử chat
  Future<void> _clearChat() async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử chat'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _chatService.clearMessages();
      setState(() => _messages.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã xóa lịch sử chat' : 'Không thể xóa lịch sử chat'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Nút Clear Chat
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa lịch sử',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(child: _buildMessageList()),
          
          // TextField và nút Send
          _buildInputArea(),
        ],
      ),
    );
  }

  /// Xây dựng danh sách tin nhắn
  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Hãy hỏi AI về việc học của bạn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg['user']!, msg['ai']!);
      },
    );
  }

  /// Xây dựng một cặp tin nhắn (user + AI)
  Widget _buildMessageBubble(String userMessage, String aiResponse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tin nhắn user (bên phải)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Text(
                userMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          
          // Khoảng cách
          const SizedBox(height: 8),
          
          // Tin nhắn AI (bên trái)
          if (aiResponse.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Text(aiResponse),
              ),
            )
          else
            // Hiển thị loading khi đang chờ AI response
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Xây dựng TextField và nút Send
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // TextField
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập câu hỏi...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isSending,
              ),
            ),
            const SizedBox(width: 8),
            
            // Nút Send
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
