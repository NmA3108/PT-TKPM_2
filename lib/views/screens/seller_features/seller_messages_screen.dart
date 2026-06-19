import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/providers/auth_provider.dart';
import 'seller_customer_chat_screen.dart';
import 'seller_feature_service.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF111827);
const _secondaryTextColor = Color(0xFF6B7280);

class SellerMessagesScreen extends StatelessWidget {
  const SellerMessagesScreen({super.key});

  static final _service = SellerFeatureService();

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<AuthProvider>().currentUser;
    final sellerId = seller?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: const Text('Tin nhan khach hang')),
      body: sellerId == null
          ? const _MessageState(message: 'Vui long dang nhap bang tai khoan seller.')
          : StreamBuilder<List<SellerCustomerConversationModel>>(
              stream: _service.watchCustomerConversations(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Khong the tai tin nhan.\n${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final conversations =
                    snapshot.data ?? const <SellerCustomerConversationModel>[];
                if (conversations.isEmpty) {
                  return const _MessageState(
                    message: 'Chua co khach hang nao nhan tin.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _CustomerConversationTile(
                      conversation: conversation,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SellerCustomerChatScreen(
                            sellerId: sellerId,
                            sellerName: seller?.displayName ?? 'Seller000',
                            customerId: conversation.customerId,
                            customerName: conversation.customerName,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _CustomerConversationTile extends StatelessWidget {
  const _CustomerConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final SellerCustomerConversationModel conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  conversation.customerName.isEmpty
                      ? 'K'
                      : conversation.customerName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primaryTextColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage.isEmpty
                          ? 'Bat dau hoi thoai'
                          : conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _secondaryTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: _secondaryTextColor),
            ],
          ),
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
