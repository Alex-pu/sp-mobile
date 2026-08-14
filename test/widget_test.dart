import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sp_mobile/src/app.dart';
import 'package:sp_mobile/src/data/models/shop.dart';
import 'package:sp_mobile/src/features/pairing/pairing_controller.dart';

class TestPairingController extends PairingController {
  @override
  Future<Shop?> build() async => null;
}

void main() {
  testWidgets('shows role selection before login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pairingControllerProvider.overrideWith(TestPairingController.new),
        ],
        child: const SmartPosApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chui POS'), findsWidgets);
    expect(find.text('Business owner'), findsOneWidget);
    expect(find.text('Cashier'), findsOneWidget);
  });
}
