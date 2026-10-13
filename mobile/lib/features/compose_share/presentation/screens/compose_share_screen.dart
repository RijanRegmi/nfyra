import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/constants/nfc_constants.dart';
import '../../../../core/security/keystore_service.dart';
import '../../../history/domain/entities/history_message.dart';
import '../../../history/domain/usecases/save_history_message_usecase.dart';
import '../bloc/compose_share_bloc.dart';

class ComposeShareScreen extends StatefulWidget {
  const ComposeShareScreen({super.key});

  @override
  State<ComposeShareScreen> createState() => _ComposeShareScreenState();
}

class _ComposeShareScreenState extends State<ComposeShareScreen> {
  final _controller = TextEditingController();
  bool _isLink = false;
  static const _maxChars = 800;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > _maxChars) return false;
    if (_isLink) {
      final uri = Uri.tryParse(text);
      return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    }
    return true;
  }

  Future<bool> _biometricGate(BuildContext context) async {
    final keystore = GetIt.I<KeystoreService>();
    final bioPref = await keystore.secureRead('setting_biometric_required');
    if (bioPref == 'false') {
      return true; // User turned off biometric requirement in settings
    }

    final auth = LocalAuthentication();
    final isSupported = await auth.isDeviceSupported();
    final canCheck = await auth.canCheckBiometrics;
    if (!isSupported && !canCheck) return true;

    try {
      return await auth.authenticate(
        localizedReason: 'Scan your fingerprint or enter PIN to share via NFC',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allows Fingerprint, Face, PIN, or Pattern
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _onShare(BuildContext context, ComposeShareBloc bloc) async {
    final authed = await _biometricGate(context);
    if (!authed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric verification required to share message'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                context.go(AppRoutes.settings);
              },
            ),
          ),
        );
      }
      return;
    }

    final content = _controller.text.trim();
    final type = _isLink ? 'link' : 'text';

    // Save to local encrypted history
    try {
      final saveHistory = GetIt.I<SaveHistoryMessageUsecase>();
      await saveHistory(HistoryMessage(
        id: const Uuid().v4(),
        content: content,
        type: type,
        direction: MessageDirection.sent,
        timestamp: DateTime.now().toUtc(),
      ));
    } catch (_) {}

    bloc.add(ComposeShareStartEvent(
      content: content,
      type: type,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<ComposeShareBloc>(),
      child: BlocConsumer<ComposeShareBloc, ComposeShareState>(
        listener: (context, state) {
          if (state is ComposeShareSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✓ Message sent via NFC')),
            );
          } else if (state is ComposeShareTimedOut) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share window expired')),
            );
          } else if (state is ComposeShareError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<ComposeShareBloc>();
          final isArmed = state is ComposeShareArmed;
          final cs = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Nfyra'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.wifi_tethering_rounded,
                      color: isArmed ? cs.primary : cs.onSurfaceVariant),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type toggle
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: false,
                            icon: Icon(Icons.text_fields),
                            label: Text('Text')),
                        ButtonSegment(
                            value: true,
                            icon: Icon(Icons.link_rounded),
                            label: Text('Link')),
                      ],
                      selected: {_isLink},
                      onSelectionChanged: isArmed
                          ? null
                          : (v) => setState(() {
                                _isLink = v.first;
                                _controller.clear();
                              }),
                    ),
                    const SizedBox(height: 20),

                    // Message field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        maxLength: _maxChars,
                        readOnly: isArmed,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(
                              RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]')),
                        ],
                        keyboardType:
                            _isLink ? TextInputType.url : TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: _isLink
                              ? 'https://example.com'
                              : 'Type your message…',
                          alignLabelWithHint: true,
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    // Char counter
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_controller.text.length} / $_maxChars',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _controller.text.length > _maxChars
                                  ? cs.error
                                  : cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Armed countdown or Share button
                    if (isArmed) ...[
                      _CountdownWidget(secondsRemaining: state.secondsRemaining),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => bloc.add(const ComposeShareCancelEvent()),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(color: cs.error),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ] else if (state is ComposeShareArming) ...[
                      const SizedBox(
                        height: 52,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ] else ...[
                      FilledButton.icon(
                        onPressed: _isValid
                            ? () => _onShare(context, bloc)
                            : null,
                        icon: const Icon(Icons.nfc_rounded),
                        label: const Text('Share via NFC'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CountdownWidget extends StatelessWidget {
  final int secondsRemaining;
  const _CountdownWidget({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fraction = secondsRemaining / kShareWindowSeconds;
    final color = fraction > 0.4 ? cs.primary : cs.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 6,
                  color: color,
                  backgroundColor: color.withAlpha(51),
                ),
              ),
              Text(
                '$secondsRemaining',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nfc_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                'Touch phones together to share',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
