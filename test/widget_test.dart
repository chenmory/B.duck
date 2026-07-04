import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duck_parent_app/app.dart';

void main() {
  testWidgets('login flow opens dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const DuckParentApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('账号'), 'parent@example.com');
    await tester.enterText(find.bySemanticsLabel('密码'), '123456');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsOneWidget);
    expect(find.textContaining('今天小鸭陪伴了'), findsOneWidget);
  });
}
