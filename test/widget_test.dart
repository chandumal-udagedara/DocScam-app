import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doc_scam_mobile_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Use a larger surface to avoid overflow errors on the welcome screen
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DocScamApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
