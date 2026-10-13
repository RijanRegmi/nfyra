import 'package:equatable/equatable.dart';

class ReceivedMessage extends Equatable {
  final String id;
  final String type; // 'text' | 'link'
  final String content;
  final DateTime receivedAt;
  final DateTime createdAt; // sender's time
  final String senderKeyId;
  final bool signatureVerified;

  const ReceivedMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.receivedAt,
    required this.createdAt,
    required this.senderKeyId,
    required this.signatureVerified,
  });

  @override
  List<Object> get props => [id];
}
