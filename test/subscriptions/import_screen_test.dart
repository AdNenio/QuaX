import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quax/subscriptions/_import.dart';

import '../ui/pump_app.dart';

void main() {
  FilledButton importButton(WidgetTester tester) => tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('Should only offer to import once a username is typed', (tester) async {
    await pumpInApp(tester, const SubscriptionImportScreen());

    expect(importButton(tester).onPressed, isNull, reason: 'There is no account to import from yet');

    await tester.enterText(find.byType(TextFormField), 'someone');
    await tester.pump();

    expect(importButton(tester).onPressed, isNotNull, reason: 'A username is all the import needs');
  });

  testWidgets('Should be ready to import the account it was opened for', (tester) async {
    await pumpInApp(tester, const SubscriptionImportScreen(screenName: 'me'));

    expect(find.text('me'), findsOneWidget, reason: 'The username should be filled in already');
    expect(importButton(tester).onPressed, isNotNull, reason: 'Nothing is left to type before importing');
  });
}
