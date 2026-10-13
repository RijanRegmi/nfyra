import 'package:equatable/equatable.dart';

enum MessageDirection { sent, received }

class HistoryMessage extends Equatable {
  final String id;
  final String content;
  final String type; // 'text' | 'link'
  final MessageDirection direction;
  final DateTime timestamp;
  final String? peerKeyFingerprint;

  const HistoryMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.direction,
    required this.timestamp,
    this.peerKeyFingerprint,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type,
        'direction': direction.name,
        'timestamp': timestamp.toIso8601String(),
        'peerKeyFingerprint': peerKeyFingerprint,
      };

  factory HistoryMessage.fromJson(Map<String, dynamic> json) {
    return HistoryMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      direction: MessageDirection.values.firstWhere(
        (d) => d.name == json['direction'],
        orElse: () => MessageDirection.received,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      peerKeyFingerprint: json['peerKeyFingerprint'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, content, type, direction, timestamp, peerKeyFingerprint];
}
