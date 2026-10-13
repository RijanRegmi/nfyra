import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tramessage/features/nfc_gate/domain/entities/nfc_status_entity.dart';
import 'package:tramessage/features/nfc_gate/presentation/bloc/nfc_gate_bloc.dart';
import 'package:tramessage/features/nfc_gate/presentation/screens/nfc_gate_screen.dart';

class MockNfcGateBloc extends Mock implements NfcGateBloc {}

void main() {
  testWidgets('NfcGateScreen renders blocking screen when NFC is disabled',
      (WidgetTester tester) async {
    final mockBloc = MockNfcGateBloc();
    when(() => mockBloc.state).thenReturn(
      const NfcGateUnsupported(
        NfcStatusEntity(
          hasHardware: true,
          isEnabled: false,
          hasHce: true,
        ),
      ),
    );
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: NfcGateScreen(bloc: mockBloc),
      ),
    );

    expect(find.text('NFC Required'), findsOneWidget);
    expect(find.text('Open NFC Settings'), findsOneWidget);
  });
}
