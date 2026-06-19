import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/providers/auth_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'account_feature_service.dart';
import 'seller_chat_detail_screen.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _accentColor = Color(0xFF5D3FD3);

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static final _service = AccountFeatureService();

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: userId == null
          ? const _MessageState(message: 'Vui lòng đăng nhập để xem tin nhắn.')
          : StreamBuilder<List<SellerConversationModel>>(
              stream: _service.watchSellerConversations(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Không thể tải tin nhắn.\n${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final conversations =
                    snapshot.data ?? const <SellerConversationModel>[];
                if (conversations.isEmpty) {
                  return const _MessageState(
                    message: 'Bạn chưa có tin nhắn nào.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _ConversationTile(
                      conversation: conversation,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SellerChatDetailScreen(
                              sellerId: conversation.sellerId,
                              sellerName: conversation.sellerName,
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final SellerConversationModel conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: _surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: CircleAvatar(
        backgroundColor: _accentColor.withOpacity(0.12),
        child: const Icon(Icons.storefront_outlined, color: _accentColor),
      ),
      title: Text(
        conversation.sellerName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        conversation.lastMessage.isEmpty
            ? 'Nhắn để tiếp tục trò chuyện'
            : conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
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
