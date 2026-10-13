import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/security/auto_share_service.dart';

class AutoShareScreen extends StatefulWidget {
  const AutoShareScreen({super.key});

  @override
  State<AutoShareScreen> createState() => _AutoShareScreenState();
}

class _AutoShareScreenState extends State<AutoShareScreen> {
  final _controller = TextEditingController();
  final AutoShareService _autoShareService = GetIt.I<AutoShareService>();

  bool _isLink = false;
  bool _isEnabled = false;
  bool _isBatteryOptimized = true; // true means system may kill background
  bool _isLoading = true;

  static const int _maxChars = 800;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    try {
      final data = await _autoShareService.getAutoShare();
      final ignoring = await _autoShareService.isIgnoringBatteryOptimizations();

      if (mounted) {
        setState(() {
          _isEnabled = data['enabled'] as bool;
          _isLink = (data['type'] as String) == 'link';
          _controller.text = data['content'] as String;
          _isBatteryOptimized = !ignoring;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _saveAndToggle(bool enabled, {bool showFeedback = true}) async {
    if (enabled && !_isValid) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid message or https link first.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final type = _isLink ? 'link' : 'text';
    final content = _controller.text.trim();

    await _autoShareService.saveAutoShare(
      type: type,
      content: content,
      enabled: enabled,
    );

    setState(() {
      _isEnabled = enabled;
    });

    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? '⚡ Background Auto-Share is now ARMED! Touch another phone anytime to share.'
                : 'Auto-Share disabled.',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
    }
  }

  Future<void> _requestBackgroundPermission() async {
    await _autoShareService.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(milliseconds: 500));
    final ignoring = await _autoShareService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _isBatteryOptimized = !ignoring;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Auto-Share'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            // Status Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isEnabled ? cs.primary : cs.outlineVariant,
                  width: _isEnabled ? 2 : 1,
                ),
              ),
              color: _isEnabled
                  ? cs.primaryContainer.withValues(alpha: 0.25)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isEnabled
                          ? Icons.offline_bolt_rounded
                          : Icons.do_not_disturb_on_rounded,
                      size: 36,
                      color: _isEnabled ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEnabled ? 'Auto-Share Active' : 'Auto-Share Off',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isEnabled ? cs.primary : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEnabled
                                ? 'Touch another phone anytime to automatically transfer this message, even with Nfyra closed.'
                                : 'Toggle below to automatically send your saved message whenever another phone touches yours.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Battery Optimization Banner (if permission not yet given)
            if (_isBatteryOptimized)
              Card(
                elevation: 0,
                color: cs.tertiaryContainer.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.tertiary.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.battery_saver_rounded, color: cs.tertiary),
                          const SizedBox(width: 8),
                          Text(
                            'Background Permission Needed',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'To prevent Android battery saver from freezing NFC card emulation when the app is in the background, allow unrestricted background running.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: _requestBackgroundPermission,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Allow Background Running'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isBatteryOptimized) const SizedBox(height: 20),

            // Enable switch
            SwitchListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
              title: const Text('Enable Always-Armed Auto-Share'),
              subtitle: const Text('Automatically share on NFC contact'),
              value: _isEnabled,
              onChanged: _saveAndToggle,
            ),
            const SizedBox(height: 20),

            // Message Type Toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.text_fields),
                  label: Text('Plain Text'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.link_rounded),
                  label: Text('HTTPS Link'),
                ),
              ],
              selected: {_isLink},
              onSelectionChanged: (v) {
                setState(() {
                  _isLink = v.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Message Input
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: _maxChars,
              inputFormatters: [
                FilteringTextInputFormatter.deny(
                  RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
                ),
              ],
              keyboardType:
                  _isLink ? TextInputType.url : TextInputType.multiline,
              decoration: InputDecoration(
                labelText: _isLink
                    ? 'Saved Link (e.g. Website or Social)'
                    : 'Saved Message (e.g. Contact, Bio, or Note)',
                hintText: _isLink ? 'https://example.com' : 'Enter message…',
                alignLabelWithHint: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),

            // Save / Update Button
            FilledButton.icon(
              onPressed: _isValid
                  ? () => _saveAndToggle(true)
                  : null,
              icon: const Icon(Icons.save_rounded),
              label: Text(_isEnabled ? 'Update Saved Message' : 'Save & Arm Auto-Share'),
            ),
            if (_isEnabled) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _saveAndToggle(false),
                icon: const Icon(Icons.pause_circle_outline_rounded),
                label: const Text('Turn Off Auto-Share'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
