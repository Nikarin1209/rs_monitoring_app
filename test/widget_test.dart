import 'package:flutter_test/flutter_test.dart';
import 'package:rs_monitoring_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroLifeApp());
    expect(find.text('NeuroLife'), findsOneWidget);
  });
}
