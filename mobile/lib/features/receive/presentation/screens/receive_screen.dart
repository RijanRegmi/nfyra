import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/routes.dart';
import '../../data/datasources/nfc_receive_datasource.dart';
import '../bloc/receive_bloc.dart';

class ReceiveScreen extends StatefulWidget {
  final Map<String, dynamic>? payload;

  const ReceiveScreen({super.key, this.payload});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  late final ReceiveBloc _bloc;
  StreamSubscription? _payloadSubscription;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.I<ReceiveBloc>();

    if (widget.payload != null) {
      _bloc.add(ReceiveProcessPayloadEvent(widget.payload!));
    }

    // Also listen to incoming background NFC events via datasource
    try {
      final datasource = GetIt.I<NfcReceiveDatasource>();
      _payloadSubscription = datasource.payloadStream.listen((event) {
        _bloc.add(ReceiveProcessPayloadEvent(event));
      }, onError: (err) {
        // Stream errors handled in bloc
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _payloadSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleOpenLink(BuildContext context, String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('External Link Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are about to open an external link in your web browser. Make sure you trust the sender before continuing.\n',
              style: TextStyle(fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open in Browser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.scheme.toLowerCase() == 'https') {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming NFC Message'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.compose);
            }
          },
        ),
      ),
      body: BlocConsumer<ReceiveBloc, ReceiveState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is ReceiveFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReceiveLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying Ed25519 signature & payload integrity...'),
                ],
              ),
            );
          }

          if (state is ReceiveSuccess) {
            final msg = state.message;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification badge banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cryptographically Verified',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                'Sender key & Ed25519 signature verified. Nonce deduplicated.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Message card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                avatar: Icon(
                                  msg.type == 'link'
                                      ? Icons.link_rounded
                                      : Icons.notes_rounded,
                                  size: 16,
                                ),
                                label: Text(msg.type.toUpperCase()),
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(msg.createdAt.toLocal()),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          // Content rendered as pure plain text only (never HTML/WebView)
                          SelectableText(
                            msg.content,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  if (msg.type == 'link')
                    FilledButton.icon(
                      onPressed: () => _handleOpenLink(context, msg.content),
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('Review and Open Link'),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context, msg.content),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy to Clipboard'),
                  ),
                  const SizedBox(height: 24),

                  // Metadata section
                  ExpansionTile(
                    title: const Text('Cryptographic Metadata'),
                    leading: const Icon(Icons.fingerprint_rounded),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sender Public Key Fingerprint:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            SelectableText(
                              msg.senderKeyId,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            const Text('Message ID / Nonce:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            SelectableText(
                              msg.id,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          if (state is ReceiveFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gpp_bad_rounded,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Payload Rejected',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        _bloc.add(const ReceiveResetEvent());
                        context.go(AppRoutes.compose);
                      },
                      child: const Text('Return to Home'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Initial / Waiting state
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contactless_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ready to Receive',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hold your phone back-to-back against the sender phone to receive a message via NFC.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
