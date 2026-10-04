import 'dart:math';

import 'package:quax/client/accounts.dart';
import 'package:quax/client/client.dart';
import 'package:quax/constants.dart';
import 'package:quax/database/entities.dart';
import 'package:quax/database/repository.dart';
import 'package:quax/group/group_model.dart';
import 'package:quax/import_data_model.dart';
import 'package:quax/subscriptions/users_model.dart';

/// How many accounts [screenName] follows, and how many QuaX can follow before X rate limits the feeds.
class SubscriptionImportSize {
  final int? count;
  final int limit;

  const SubscriptionImportSize({required this.count, required this.limit});

  bool get exceedsLimit => count != null && count! > limit;
}

/// The most subscriptions [accounts] can follow before X rate limits the feeds, rounded down to the ten, as a precise
/// number such as 256 would wrongly suggest that one more breaks the feeds.
int subscriptionLimit(int accounts) => maxSubscriptionsPerAccount * max<int>(1, accounts) ~/ 10 * 10;

/// Imports the accounts a user follows on X as QuaX subscriptions.
class SubscriptionImporter {
  final ImportDataModel importModel;
  final GroupsModel groupsModel;
  final SubscriptionsModel subscriptionsModel;

  const SubscriptionImporter(this.importModel, this.groupsModel, this.subscriptionsModel);

  Future<SubscriptionImportSize> size(String screenName) async {
    final count = (await Twitter.getProfileByScreenName(screenName)).user.friendsCount;
    return SubscriptionImportSize(count: count, limit: subscriptionLimit((await getAccounts()).length));
  }

  /// Imports at most [maxCount] followed accounts, emitting how many were imported so far.
  Stream<int> import(String screenName, int maxCount) async* {
    String? cursor;
    int total = 0;
    final seenIds = <String>{};
    final createdAt = DateTime.now();

    while (true) {
      final response = await Twitter.getProfileFollows(screenName, 'following', cursor: cursor);

      final next = response.cursorBottom;
      final fresh =
          response.users.where((e) => e.idStr != null && seenIds.add(e.idStr!)).take(maxCount - total).toList();

      if (fresh.isNotEmpty) {
        total = total + fresh.length;
        await importModel.importData({
          tableSubscription: [
            ...fresh.map((e) => UserSubscription(
                id: e.idStr!,
                name: e.name!,
                profileImageUrlHttps: e.profileImageUrlHttps,
                screenName: e.screenName!,
                verified: e.verified ?? false,
                createdAt: createdAt,
                inFeed: true))
          ]
        });

        yield total;
      }

      if (next == null || next.isEmpty || next == '0' || next == cursor || fresh.isEmpty || total >= maxCount) {
        break;
      }
      cursor = next;
    }

    await groupsModel.reloadGroups();
    await subscriptionsModel.reloadSubscriptions();
  }
}
