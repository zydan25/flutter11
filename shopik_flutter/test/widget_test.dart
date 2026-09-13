import 'package:flutter_test/flutter_test.dart';
import 'package:shopik_flutter/main.dart';

void main() {
  testWidgets('Shopik app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopikApp());
    await tester.pump();
    expect(find.textContaining('شبيك'), findsWidgets);
  });
}
