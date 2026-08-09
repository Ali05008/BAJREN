import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bajren/main.dart';
import 'package:bajren/core/di/firebase_ready.dart';

void main() {
  testWidgets('BAJREN shows login when signed out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWithValue(false),
        ],
        child: const BajrenApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('BAJREN'), findsWidgets);
  });
}
