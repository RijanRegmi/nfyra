import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/security/keystore_service.dart';
import '../../../history/domain/usecases/clear_history_usecase.dart';
import '../../../../core/usecases/usecase.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final KeystoreService _keystore = GetIt.I<KeystoreService>();
  String _keyFingerprint = 'Loading...';
  bool _biometricRequired = true;
  String _autoDeleteDuration = 'never'; // 'never', '1h', '24h', '7d'

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final key = await _keystore.getKeyId();
      final bio = await _keystore.secureRead('setting_biometric_required');
      final autoDel = await _keystore.secureRead('setting_auto_delete');

      if (mounted) {
        setState(() {
          _keyFingerprint = key;
          _biometricRequired = bio == null ? true : bio == 'true';
          _autoDeleteDuration = autoDel ?? 'never';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _keyFingerprint = 'Unavailable';
        });
      }
    }
  }

  Future<void> _updateBiometric(bool value) async {
    if (value) {
      final auth = LocalAuthentication();
      try {
        final authed = await auth.authenticate(
          localizedReason: 'Scan your biometric to turn on sharing protection',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        if (!authed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric verification failed. Protection remains off.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric error: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    setState(() => _biometricRequired = value);
    await _keystore.secureWrite('setting_biometric_required', value.toString());
  }

  Future<void> _updateAutoDelete(String value) async {
    setState(() => _autoDeleteDuration = value);
    await _keystore.secureWrite('setting_auto_delete', value);
  }

  void _copyKeyFingerprint() {
    Clipboard.setData(ClipboardData(text: _keyFingerprint));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identity key fingerprint copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase All Data?'),
        content: const Text(
          'This will permanently delete all message history, nonces, and local preferences. Your hardware keypair will remain intact in Android Keystore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Erase Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final clearHistory = GetIt.I<ClearHistoryUsecase>();
      await clearHistory(const NoParams());
      await _keystore.secureDelete('nonce_cache');
      await _keystore.secureDelete('setting_biometric_required');
      await _keystore.secureDelete('setting_auto_delete');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local data wiped cleanly.')),
        );
        _loadSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // Security Status Card
          Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: theme.colorScheme.secondary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Offline & Private',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zero internet permissions, hardware-backed keys, and FLAG_SECURE screen protection.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Key Fingerprint Section
          Text(
            'DEVICE IDENTITY',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded),
                      const SizedBox(width: 8),
                      Text(
                        'Hardware Key Fingerprint',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Copy Fingerprint',
                        onPressed: _copyKeyFingerprint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      _keyFingerprint,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compare this fingerprint in person with peers to verify message authenticity.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Protection Settings
          Text(
            'PROTECTION PREFERENCES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Biometric Gate for Sharing'),
                  subtitle: const Text('Require fingerprint/biometric prompt before arming NFC.'),
                  value: _biometricRequired,
                  onChanged: _updateBiometric,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Auto-Delete History'),
                  subtitle: Text(
                    _autoDeleteDuration == 'never'
                        ? 'Never delete'
                        : 'Delete after $_autoDeleteDuration',
                  ),
                  trailing: DropdownButton<String>(
                    value: _autoDeleteDuration,
                    underline: const SizedBox.shrink(),
                    onChanged: (val) {
                      if (val != null) _updateAutoDelete(val);
                    },
                    items: const [
                      DropdownMenuItem(value: 'never', child: Text('Never')),
                      DropdownMenuItem(value: '1h', child: Text('1 Hour')),
                      DropdownMenuItem(value: '24h', child: Text('24 Hours')),
                      DropdownMenuItem(value: '7d', child: Text('7 Days')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data Management
          Text(
            'DATA DESTRUCTION',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
              title: Text(
                'Clear All Local Data',
                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Wipes encrypted history, nonces, and app settings.'),
              onTap: _clearAllData,
            ),
          ),
        ],
      ),
    );
  }
}
