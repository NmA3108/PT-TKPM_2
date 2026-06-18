import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';

const _backgroundColor = Color(0xFFF7F7F9);
const _primaryColor = Color(0xFF5D5FEF);
const _titleColor = Color(0xFF20204A);
const _mutedColor = Color(0xFF8B8BA8);

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text: 'Xin chào! Mình có thể hỗ trợ bạn tìm sản phẩm, kiểm tra giỏ hàng hoặc hướng dẫn thanh toán.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                children: [
                  const _BotIntro(),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 190,
                    child: PageView(
                      controller: PageController(viewportFraction: 0.78),
                      children: [
                        _PromptCard(
                          iconColor: _primaryColor,
                          title: 'Tư vấn mua sắm',
                          content: 'Gợi ý sản phẩm phù hợp với ngân sách của tôi.',
                          onTap: () => _usePrompt(
                            'Gợi ý sản phẩm phù hợp với ngân sách của tôi.',
                          ),
                        ),
                        _PromptCard(
                          iconColor: const Color(0xFF10B981),
                          title: 'Tìm sản phẩm',
                          content: 'Tôi muốn tìm sản phẩm theo danh mục và giá.',
                          onTap: () => _usePrompt(
                            'Tôi muốn tìm sản phẩm theo danh mục và giá.',
                          ),
                        ),
                        _PromptCard(
                          iconColor: const Color(0xFFFF7A59),
                          title: 'Hỗ trợ đơn hàng',
                          content: 'Hướng dẫn tôi kiểm tra trạng thái đơn hàng.',
                          onTap: () => _usePrompt(
                            'Hướng dẫn tôi kiểm tra trạng thái đơn hàng.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final message in _messages) _MessageBubble(message: message),
                ],
              ),
            ),
            _ChatInput(
              controller: _messageController,
              onSend: _sendMessage,
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  void _usePrompt(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(
        _ChatMessage(
          text: _fakeAnswer(text),
          isUser: false,
        ),
      );
      _messageController.clear();
    });
  }

  String _fakeAnswer(String text) {
    final normalized = text.toLowerCase();
    if (normalized.contains('giỏ') || normalized.contains('cart')) {
      return 'Bạn có thể mở Giỏ hàng, cập nhật số lượng, xóa sản phẩm rồi bấm Đặt hàng để tiếp tục.';
    }
    if (normalized.contains('thanh toán') || normalized.contains('payment')) {
      return 'Ở bước thanh toán, bạn chọn địa chỉ, áp voucher, chọn COD/ví/ngân hàng rồi xác nhận đơn hàng.';
    }
    if (normalized.contains('sản phẩm') || normalized.contains('giá')) {
      return 'Bạn có thể tìm sản phẩm trên trang chủ, mở chi tiết để chọn phân loại, số lượng và thêm vào giỏ.';
    }
    return 'Mình đã ghi nhận yêu cầu. Bạn có thể mô tả rõ hơn sản phẩm, ngân sách hoặc vấn đề cần hỗ trợ nhé.';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Chatbot',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9DFF00),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotIntro extends StatelessWidget {
  const _BotIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.smart_toy_rounded,
          size: 84,
          color: _primaryColor,
        ),
        const SizedBox(height: 14),
        Text(
          'Xin chào!\nMình sẵn sàng hỗ trợ bạn',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _titleColor,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Hỏi mình về sản phẩm, giỏ hàng, đặt hàng hoặc thanh toán.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _mutedColor,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.iconColor,
    required this.title,
    required this.content,
    required this.onTap,
  });

  final Color iconColor;
  final String title;
  final String content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor,
            child: const Icon(Icons.psychology_alt_rounded, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: _titleColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(color: Color(0xFFB8B8C8), height: 1.35),
            ),
          ),
          SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: onTap,
              child: const Text('Dùng gợi ý'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: message.isUser ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : _titleColor,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi...',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 28,
            backgroundColor: _primaryColor,
            child: IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.mic_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}
