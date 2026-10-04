import 'package:quax/subscriptions/subscription_importer.dart';

/// Imports [following] accounts without reaching X, and remembers what it was asked.
class FakeImporter implements SubscriptionImporter {
  final int following;
  final int limit;
  final Object? error;
  final requests = <(String, int)>[];

  FakeImporter({this.following = 3, this.limit = 300, this.error});

  @override
  Future<SubscriptionImportSize> size(String screenName) async {
    if (error != null) {
      throw error!;
    }
    return SubscriptionImportSize(count: following, limit: limit);
  }

  @override
  Stream<int> import(String screenName, int maxCount) async* {
    requests.add((screenName, maxCount));
    final total = following < maxCount ? following : maxCount;
    for (var imported = 1; imported <= total; imported++) {
      yield imported;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
