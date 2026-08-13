import 'chat_summary.dart';
import 'message.dart';

abstract class ChatRepository {
  /// Deterministic chat id for a pair of users — the two uids sorted and
  /// joined with `_`, so both participants always compute the same id
  /// regardless of who initiated the conversation.
  String chatIdFor(String uidA, String uidB);

  /// Live list of the signed-in user's conversations, most recent first.
  Stream<List<ChatSummary>> watchChatList(String uid);

  /// Live message history for one conversation, oldest first.
  Stream<List<Message>> watchMessages(String chatId);

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderDisplayName,
    required String recipientUid,
    required String recipientDisplayName,
    required String text,
  });
}
