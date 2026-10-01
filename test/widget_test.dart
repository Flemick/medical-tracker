import 'package:flutter_test/flutter_test.dart';
import 'package:medical_tracking/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicalTrackingApp());
    expect(find.byType(MedicalTrackingApp), findsOneWidget);
  });
}
