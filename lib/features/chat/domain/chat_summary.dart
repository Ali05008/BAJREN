import 'package:equatable/equatable.dart';

/// One row in the chat list: the other participant plus a preview of the
/// most recent message. Denormalized under `/user_chats/{uid}/{chatId}`
/// so the chat list never needs to scan every conversation's full
/// message history just to render previews.
class ChatSummary extends Equatable {
  final String chatId;
  final String otherUid;
  final String otherDisplayName;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const ChatSummary({
    required this.chatId,
    required this.otherUid,
    required this.otherDisplayName,
    this.lastMessage,
    this.lastMessageAt,
  });

  @override
  List<Object?> get props => [chatId, otherUid, lastMessage, lastMessageAt];
}
