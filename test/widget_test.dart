import 'package:flutter_test/flutter_test.dart';

import 'package:control_medicoapp/main.dart';

void main() {
  testWidgets('Shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
