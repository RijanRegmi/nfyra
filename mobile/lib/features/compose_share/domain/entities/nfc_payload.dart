import 'package:equatable/equatable.dart';

class NfcPayload extends Equatable {
  final int v;
  final String type; // 'text' | 'link'
  final String content;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String nonce;
  final String senderKeyId;
  final String signature;

  const NfcPayload({
    required this.v,
    required this.type,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
    required this.nonce,
    required this.senderKeyId,
    required this.signature,
  });

  @override
  List<Object> get props => [nonce, senderKeyId, signature];
}
