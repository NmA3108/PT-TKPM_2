import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/providers/auth_provider.dart';
import 'account_feature_service.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _accentColor = Color(0xFF5D3FD3);

class SellerChatDetailScreen extends StatefulWidget {
  const SellerChatDetailScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  final String sellerId;
  final String sellerName;

  @override
  State<SellerChatDetailScreen> createState() {
    return _SellerChatDetailScreenState();
  }
}

class _SellerChatDetailScreenState extends State<SellerChatDetailScreen> {
  final _service = AccountFeatureService();
  final _messageController = TextEditingController();
  var _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final userId = user?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: Text(widget.sellerName)),
      body: userId == null
          ? const _MessageState(message: 'Vui long dang nhap de nhan tin.')
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<SellerChatMessageModel>>(
                    stream: _service.watchMessages(
                      userId: userId,
                      sellerId: widget.sellerId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _MessageState(
                          message: 'Khong the tai tin nhan.\n${snapshot.error}',
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages =
                          snapshot.data ?? const <SellerChatMessageModel>[];
                      if (messages.isEmpty) {
                        return const _MessageState(
                          message: 'Hay bat dau cuoc tro chuyen voi seller.',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _MessageBubble(message: messages[index]);
                        },
                      );
                    },
                  ),
                ),
                _InputBar(
                  controller: _messageController,
                  isSending: _isSending,
                  onSend: () => _send(
                    userId: userId,
                    customerName: user?.displayName ?? 'Customer000',
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _send({
    required String userId,
    required String customerName,
  }) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await _service.sendMessage(
        userId: userId,
        sellerId: widget.sellerId,
        sellerName: widget.sellerName,
        text: text,
        customerName: customerName,
      );
      _messageController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gui tin nhan that bai: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SellerChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isCustomer;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? _accentColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isMine ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Nhap tin nhan...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
