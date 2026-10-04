import 'package:flutter_test/flutter_test.dart';
import 'package:quax/constants.dart';
import 'package:quax/subscriptions/subscription_importer.dart';

void main() {
  group('subscriptionLimit()', () {
    test('Should round the limit down to the ten', () {
      expect(subscriptionLimit(1) % 10, 0, reason: 'A round number reads as the guideline it is');
      expect(subscriptionLimit(1), lessThanOrEqualTo(maxSubscriptionsPerAccount),
          reason: 'Rounding up would offer to import more than X lets the feeds load');
      expect(maxSubscriptionsPerAccount - subscriptionLimit(1), lessThan(10),
          reason: 'Only the units should be dropped, not a whole ten');
    });

    test('Should grow with the number of accounts', () {
      expect(subscriptionLimit(3), (maxSubscriptionsPerAccount * 3) ~/ 10 * 10,
          reason: 'Each account brings its own quota, so the limit is the quotas together, then rounded');
    });

    test('Should count as one account when there is none', () {
      expect(subscriptionLimit(0), subscriptionLimit(1),
          reason: 'Requests without an account still have a quota, so the limit should not drop to 0');
    });
  });
}
