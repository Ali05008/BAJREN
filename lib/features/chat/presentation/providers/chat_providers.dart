import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/firebase_chat_repository.dart';
import '../../domain/chat_repository.dart';
import '../../domain/chat_summary.dart';
import '../../domain/message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirebaseChatRepository();
});

final chatListProvider = StreamProvider<List<ChatSummary>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchChatList(uid);
});

/// Live messages for one open conversation. [chatId] is the deterministic
/// id from [ChatRepository.chatIdFor] — family so each open conversation
/// screen gets its own independent stream.
final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});
