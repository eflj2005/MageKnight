// Test básico de smoke para la aplicación Mage Knight.
// Verifica que la app arranca sin lanzar excepciones.

import 'package:flutter_test/flutter_test.dart';
import 'package:mageknight/main.dart';

void main() {
  testWidgets('Mage Knight arranca sin errores', (WidgetTester tester) async {
    // Construir la app y verificar que no lanza excepciones
    await tester.pumpWidget(const MageKnightApp());
    expect(find.byType(MageKnightApp), findsOneWidget);
  });
}
