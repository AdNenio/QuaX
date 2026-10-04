import 'package:flutter_test/flutter_test.dart';
import 'package:quax/database/entities.dart';
import 'package:quax/group/_feed.dart';

import '../ui/pump_app.dart';

void main() {
  testWidgets('Should invite to add an account when there is none', (tester) async {
    await pumpInApp(tester, EmptyGroupFeed(accounts: () async => []));

    expect(find.text('No account available right now'), findsOneWidget,
        reason: 'Without an account the feed cannot load, which matters more than having no subscriptions');
    expect(find.text('Add account'), findsOneWidget, reason: 'The user should be able to log in from the feed');
    expect(find.text('This group contains no subscriptions!'), findsNothing,
        reason: 'Subscribing would not help without an account');
  });

  testWidgets('Should say the group is empty when an account is there', (tester) async {
    await pumpInApp(
        tester, EmptyGroupFeed(accounts: () async => [Account(id: 'a1', authHeader: '{}', screenName: 'me')]));

    expect(find.text('This group contains no subscriptions!'), findsOneWidget,
        reason: 'With an account, subscribing is all the feed needs');
    expect(find.text('Add account'), findsNothing, reason: 'There is no account problem to report');
  });
}
