import 'package:flutter_test/flutter_test.dart';
import 'package:quax/database/entities.dart';
import 'package:quax/onboarding/onboarding_model.dart';

import 'fake_importer.dart';

void main() {
  group('OnboardingModel', () {
    test('Should retrace the steps the user went through when going back', () {
      final model = OnboardingModel()
        ..goTo(OnboardingStep.theme)
        ..goTo(OnboardingStep.login)
        ..goTo(OnboardingStep.noAccount);

      model.back();
      expect(model.state.step, OnboardingStep.login,
          reason: 'Going back from the warning should return to the login, which is where the user came from');
      model
        ..back()
        ..back()
        ..back();
      expect(model.state.step, OnboardingStep.welcome,
          reason: 'The welcome step is the first one, so going back should stop there');
      expect(model.state.canGoBack, isFalse, reason: 'There is no step before the welcome one');
    });

    test('Should tell whether the user went back, for the transition to play backwards', () {
      final model = OnboardingModel()..goTo(OnboardingStep.theme);
      expect(model.state.wentBack, isFalse, reason: 'Moving to the next step goes forward');

      model.back();
      expect(model.state.wentBack, isTrue, reason: 'Back should play the transition the other way');

      model.goTo(OnboardingStep.theme);
      expect(model.state.wentBack, isFalse, reason: 'Going forward again should play it forward');
    });

    test('Should remember that the welcome drawing played, to not play it again', () {
      final model = OnboardingModel()..playedWelcome();

      model
        ..goTo(OnboardingStep.theme)
        ..back();

      expect(model.state.welcomePlayed, isTrue,
          reason: 'Coming back to the welcome step should not make the user wait for the drawing again');
    });

    test('Should stay on the welcome step when no backup was picked', () async {
      final model = OnboardingModel();

      await model.importBackup(() async => false);

      expect(model.state.step, OnboardingStep.welcome,
          reason: 'Cancelling the file picker should let the user choose again');
    });

    test('Should skip to the community step once a backup is restored', () async {
      final model = OnboardingModel();

      await model.importBackup(() async => true);

      expect(model.state.step, OnboardingStep.community,
          reason: 'A backup holds the theme, the accounts and the subscriptions, so nothing else needs setting up');
    });

    test('Should go to the subscriptions with the account that logged in', () async {
      final model = OnboardingModel()..goTo(OnboardingStep.login);

      await model.logIn(() async => Account(id: 'csrf', screenName: 'me', authHeader: '{}'));

      expect(model.state.step, OnboardingStep.subscriptions,
          reason: 'Importing subscriptions is the next step after logging in');
      expect(model.state.screenName, 'me', reason: 'The import should offer the account that just logged in');
    });

    test('Should forget the account once logged out', () async {
      final model = OnboardingModel()..goTo(OnboardingStep.login);
      await model.logIn(() async => Account(id: 'csrf', screenName: 'me', authHeader: '{}'));
      model.back();
      final removed = <String>[];

      await model.logOut((account) async => removed.add(account.id));

      expect(removed, ['csrf'], reason: 'The account should be removed by its id, which is how QuaX stores it');
      expect(model.state.account, isNull, reason: 'The login step should offer to log in again');
      expect(model.state.step, OnboardingStep.login, reason: 'Logging out should stay on the login step');
    });

    test('Should stay on the login step when the user left the login page', () async {
      final model = OnboardingModel()..goTo(OnboardingStep.login);

      await model.logIn(() async => null);

      expect(model.state.step, OnboardingStep.login, reason: 'Nobody logged in, so there is nothing to import from');
    });
  });

  group('SubscriptionImportModel', () {
    test('Should import everything when the account follows fewer accounts than the limit', () async {
      final importer = FakeImporter(following: 3);
      final model = SubscriptionImportModel(importer);

      await model.prepare('me');

      expect(importer.requests, [('me', 3)], reason: 'Every followed account should be imported');
      expect(model.state, isA<ImportFinished>(), reason: 'The import should be over');
      expect((model.state as ImportFinished).imported, 3, reason: 'The summary should count every imported account');
    });

    test('Should let the user choose before importing more accounts than the limit', () async {
      final importer = FakeImporter(following: 600, limit: 300);
      final model = SubscriptionImportModel(importer);

      await model.prepare('me');

      expect(importer.requests, isEmpty, reason: 'Nothing should be imported until the user chose how much');
      final progress = model.state;
      expect(progress, isA<ImportTooLarge>(), reason: 'The user should be asked how many accounts to import');
      expect((progress as ImportTooLarge).limit, 300, reason: 'The recommended maximum should be offered');
    });

    test('Should keep the error when the size of the import cannot be read', () async {
      final model = SubscriptionImportModel(FakeImporter(error: StateError('offline')));

      await model.prepare('me');

      expect(model.error, isA<StateError>(), reason: 'The error should be shown so the user can retry');
      expect(model.isLoading, isFalse, reason: 'A failed import should not keep spinning');
    });
  });
}
