import 'package:agosalert/widgets/photo_viewer.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openPhotoViewer(
                  context,
                  url: 'https://example.com/flood.jpg',
                  heroTag: 'test-photo',
                  title: 'Juan Dela Cruz',
                  subtitle: 'Photo 2h ago · Brgy. Dau',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('opens with who / when, zooms in and out, closes', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Photo 2h ago · Brgy. Dau'), findsOneWidget);
    final viewer = find.byType(InteractiveViewer);
    final tc = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    expect(tc.value.getMaxScaleOnAxis(), 1);

    // Zoom out does nothing at 1x; zoom in zooms.
    await tester.tap(find.byIcon(CupertinoIcons.zoom_out));
    await tester.pump(const Duration(seconds: 1));
    expect(tc.value.getMaxScaleOnAxis(), 1);
    await tester.tap(find.byIcon(CupertinoIcons.zoom_in));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tc.value.getMaxScaleOnAxis(), closeTo(1.6, 0.01));

    // And back out, then close.
    await tester.tap(find.byIcon(CupertinoIcons.zoom_out));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tc.value.getMaxScaleOnAxis(), closeTo(1, 0.01));
    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('Esc closes', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
