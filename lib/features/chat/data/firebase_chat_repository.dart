import 'package:firebase_database/firebase_database.dart';

import '../domain/chat_repository.dart';
import '../domain/chat_summary.dart';
import '../domain/message.dart';

class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  static const _maxMessagesLoaded = 500;

  @override
  String chatIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Stream<List<ChatSummary>> watchChatList(String uid) {
    return _db.ref('user_chats/$uid').onValue.map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return <ChatSummary>[];

      final summaries = <ChatSummary>[];
      data.forEach((chatId, value) {
        if (value is! Map) return;

        final otherUid = value['otherUid'];
        final otherDisplayName = value['otherDisplayName'];
        if (otherUid is! String || otherDisplayName is! String) return;

        final lastMessageAtRaw = value['lastMessageAt'];
        final lastMessageAtMs = lastMessageAtRaw is int
            ? lastMessageAtRaw
            : (lastMessageAtRaw is double ? lastMessageAtRaw.toInt() : null);

        summaries.add(
          ChatSummary(
            chatId: chatId.toString(),
            otherUid: otherUid,
            otherDisplayName: otherDisplayName,
            lastMessage: value['lastMessage'] as String?,
            lastMessageAt: lastMessageAtMs == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(lastMessageAtMs),
          ),
        );
      });

      summaries.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return summaries;
    });
  }

  @override
  Stream<List<Message>> watchMessages(String chatId) {
    final query = _db
        .ref('chats/$chatId/messages')
        .orderByChild('sentAt')
        .limitToLast(_maxMessagesLoaded);

    return query.onValue.map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return <Message>[];

      final messages = <Message>[];
      data.forEach((key, value) {
        if (value is! Map) return;

        final senderId = value['senderId'];
        final text = value['text'];
        final sentAtRaw = value['sentAt'];
        final sentAtMs = sentAtRaw is int
            ? sentAtRaw
            : (sentAtRaw is double ? sentAtRaw.toInt() : null);

        if (senderId is! String || text is! String || sentAtMs == null) {
          return;
        }

        messages.add(
          Message(
            id: key.toString(),
            senderId: senderId,
            text: text,
            sentAt: DateTime.fromMillisecondsSinceEpoch(sentAtMs),
          ),
        );
      });

      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return messages;
    });
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderDisplayName,
    required String recipientUid,
    required String recipientDisplayName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final messageRef = _db.ref('chats/$chatId/messages').push();
    final now = ServerValue.timestamp;

    final updates = <String, dynamic>{
      'chats/$chatId/messages/${messageRef.key}': {
        'senderId': senderId,
        'text': trimmed,
        'sentAt': now,
      },
      'user_chats/$senderId/$chatId': {
        'otherUid': recipientUid,
        'otherDisplayName': recipientDisplayName,
        'lastMessage': trimmed,
        'lastMessageAt': now,
      },
      'user_chats/$recipientUid/$chatId': {
        'otherUid': senderId,
        'otherDisplayName': senderDisplayName,
        'lastMessage': trimmed,
        'lastMessageAt': now,
      },
    };

    await _db.ref().update(updates);
  }
}
