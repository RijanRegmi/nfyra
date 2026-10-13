import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/routes.dart';
import '../bloc/nfc_gate_bloc.dart';

class NfcGateScreen extends StatelessWidget {
  final NfcGateBloc? bloc;
  const NfcGateScreen({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<NfcGateBloc>.value(
        value: bloc!,
        child: const _NfcGateView(),
      );
    }
    return BlocProvider(
      create: (_) => GetIt.I<NfcGateBloc>()..add(const NfcGateCheckEvent()),
      child: const _NfcGateView(),
    );
  }
}

class _NfcGateView extends StatefulWidget {
  const _NfcGateView();

  @override
  State<_NfcGateView> createState() => _NfcGateViewState();
}

class _NfcGateViewState extends State<_NfcGateView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user toggles NFC in Settings and resumes the app, auto-check!
    if (state == AppLifecycleState.resumed) {
      context.read<NfcGateBloc>().add(const NfcGateCheckEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocConsumer<NfcGateBloc, NfcGateState>(
      listener: (context, state) {
        if (state is NfcGateSupported) {
          context.go(AppRoutes.compose);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildIcon(context, state, cs),
                  const SizedBox(height: 32),
                  _buildTitle(context, state),
                  const SizedBox(height: 16),
                  _buildMessage(context, state, cs),
                  const Spacer(),
                  _buildButton(context, state, cs),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(BuildContext context, NfcGateState state, ColorScheme cs) {
    if (state is NfcGateLoading) {
      return CircularProgressIndicator(color: cs.primary);
    }
    final isError = state is NfcGateUnsupported || state is NfcGateError;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: isError ? cs.errorContainer : cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isError ? Icons.nfc_outlined : Icons.nfc_rounded,
        size: 48,
        color: isError ? cs.onErrorContainer : cs.onPrimaryContainer,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, NfcGateState state) {
    String title = 'Checking NFC…';
    if (state is NfcGateUnsupported || state is NfcGateError) {
      title = 'NFC Required';
    }
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(BuildContext context, NfcGateState state, ColorScheme cs) {
    String msg = 'Nfyra needs NFC to work.';
    if (state is NfcGateUnsupported) {
      final s = state.status;
      if (!s.hasHardware) {
        msg = 'This device does not have NFC hardware. Nfyra requires NFC to transfer messages.';
      } else if (!s.isEnabled) {
        msg = 'NFC is turned off. Please toggle "Use NFC" ON in settings to use Nfyra.';
      } else if (!s.hasHce) {
        msg = 'This device does not support Host Card Emulation (HCE), which Nfyra needs to send messages via NFC.';
      }
    } else if (state is NfcGateError) {
      msg = 'Could not check NFC status: ${state.message}';
    }
    return Text(
      msg,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildButton(BuildContext context, NfcGateState state, ColorScheme cs) {
    if (state is NfcGateLoading || state is NfcGateInitial) {
      return const SizedBox.shrink();
    }
    final bloc = context.read<NfcGateBloc>();
    final isHardwareMissing = state is NfcGateUnsupported && !state.status.hasHardware;

    return Column(
      children: [
        if (!isHardwareMissing)
          FilledButton.icon(
            onPressed: () {
              bloc.add(const NfcGateOpenSettingsEvent());
            },
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Open NFC Settings'),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => bloc.add(const NfcGateCheckEvent()),
          child: const Text('Check Again'),
        ),
      ],
    );
  }
}
