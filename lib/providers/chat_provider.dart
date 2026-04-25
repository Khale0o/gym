import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single chat message.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

/// Chat history state per member id.
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addMessage(ChatMessage msg) {
    state = [...state, msg];
  }

  void appendToLast(String chunk) {
    if (state.isEmpty) return;
    final last = state.last;
    state = [
      ...state.sublist(0, state.length - 1),
      ChatMessage(text: last.text + chunk, isUser: last.isUser, time: last.time),
    ];
  }

  void clear() => state = [];
}

/// Family provider keyed by memberId.
final chatProvider =
    StateNotifierProvider.family<ChatNotifier, List<ChatMessage>, String>(
  (ref, memberId) => ChatNotifier(),
);
