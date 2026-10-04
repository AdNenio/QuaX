import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pref/pref.dart';
import 'package:quax/constants.dart';
import 'package:quax/database/entities.dart';
import 'package:quax/onboarding/_on_device_animation.dart';
import 'package:quax/onboarding/onboarding_screen.dart';

import '../ui/pump_app.dart';
import 'fake_importer.dart';

class WizardCalls {
  int discord = 0;
  int logins = 0;
  final loggedOut = <Account>[];
}

// Physical sizes, at the density of a Pixel 10
const pixel10 = Size(1080, 2424);
const pixel10Sideways = Size(2424, 1080);
const tablet = Size(2100, 3360);
const tabletSideways = Size(3360, 2100);

/// Pumps the onboarding as the app shows it: in place of the home page until it is done.
Future<WizardCalls> pumpWizard(WidgetTester tester,
    {bool backupPicked = true,
    String? loggedIn = 'me',
    FakeImporter? importer,
    List<Account> saved = const [],
    bool settle = true,
    Size screen = pixel10}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  final calls = WizardCalls();
  final actions = OnboardingActions(
    importBackup: (_) async => backupPicked,
    accounts: () async => saved,
    logIn: (_) async {
      calls.logins++;
      return loggedIn == null ? null : Account(id: 'csrf-$loggedIn', screenName: loggedIn, authHeader: '{}');
    },
    logOut: (account) async => calls.loggedOut.add(account),
    joinDiscord: (_) async => calls.discord++,
    importer: (_) => importer ?? FakeImporter(),
  );
  await pumpInApp(
    tester,
    Builder(
      builder: (context) => PrefService.of(context, listen: false).get<bool>(optionOnboardingDone)!
          ? const Text('Home page')
          : OnboardingWizard(actions: actions),
    ),
    prefs: {
      optionOnboardingDone: false,
      optionDiscordPopupDismissed: false,
      optionThemeMode: 'system',
      optionThemeColor: 'accent',
    },
    settle: settle,
  );
  return calls;
}

BasePrefService prefsOf(WidgetTester tester) => PrefService.of(tester.element(find.byType(MaterialApp)), listen: false);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> reachLogin(WidgetTester tester) async {
  await tapText(tester, 'Get started');
  await tapText(tester, 'Next');
}

void expectNoPopup() =>
    expect(find.byType(Dialog), findsNothing, reason: 'The onboarding should explain everything on its own pages');

void main() {
  testWidgets('Should offer to restore a backup or to start fresh', (tester) async {
    await pumpWizard(tester);

    expect(find.text('Welcome to QuaX'), findsOneWidget, reason: 'The first launch should open on the welcome step');
    expect(find.text('Get started'), findsOneWidget, reason: 'A newcomer should be able to set the app up');
    expect(find.text('Import backup'), findsOneWidget, reason: 'A returning user should be able to restore a backup');
    expect(find.text('Back'), findsNothing, reason: 'There is no step before the welcome one');
  });

  testWidgets('Should show that everything stays on the device with a drawing', (tester) async {
    await pumpWizard(tester);

    expect(find.byType(OnDeviceAnimation), findsOneWidget, reason: 'The welcome step should draw instead of telling');
    expect(find.byIcon(Icons.lock), findsOneWidget, reason: 'The drawing should end with the phone locked');
    expect(find.text('Browse 𝕏 with no ads or trackers. Your interactions stay on your device.'), findsOneWidget,
        reason: 'A short caption should sum the drawing up');
  });

  testWidgets('Should bring the choices in once the drawing ends', (tester) async {
    await pumpWizard(tester, settle: false);

    double opacityOf(String text) =>
        tester.widget<FadeTransition>(find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)).first)
            .opacity
            .value;
    expect(opacityOf('Get started'), 0, reason: 'The choices should wait for the drawing, not cover it');
    expect(opacityOf('Browse 𝕏 with no ads or trackers. Your interactions stay on your device.'), 0,
        reason: 'The caption sums the drawing up, so it should come once the drawing is there');

    await tester.pump(OnDeviceAnimation.duration + const Duration(milliseconds: 500));
    expect(opacityOf('Browse 𝕏 with no ads or trackers. Your interactions stay on your device.'), greaterThan(0),
        reason: 'The caption should come right after the drawing');
    expect(opacityOf('Get started'), 0,
        reason: 'The choices should wait for the caption, so that the user knows what to read first');

    await tester.pumpAndSettle();
    expect(opacityOf('Get started'), 1, reason: 'Once the drawing is over, the choices should be fully shown');
    expect(opacityOf('Import backup'), 1, reason: 'Both choices should come in');
  });

  testWidgets('Should jump to the last step once a backup is restored', (tester) async {
    await pumpWizard(tester);

    await tapText(tester, 'Import backup');

    expect(find.text("You're all set!"), findsOneWidget,
        reason: 'A backup already holds the theme, the accounts and the subscriptions');
  });

  testWidgets('Should stay on the welcome step when no backup was picked', (tester) async {
    await pumpWizard(tester, backupPicked: false);

    await tapText(tester, 'Import backup');

    expect(find.text('Welcome to QuaX'), findsOneWidget,
        reason: 'Closing the file picker should let the user choose again');
  });

  testWidgets('Should offer to choose the theme', (tester) async {
    await pumpWizard(tester);

    await tapText(tester, 'Get started');

    expect(find.text('Choose your theme'), findsOneWidget, reason: 'Starting fresh should begin with the theme');
    expect(find.text('Theme Mode'), findsOneWidget, reason: 'The light or dark mode should be chosen here');
  });

  testWidgets('Should save the chosen theme mode', (tester) async {
    await pumpWizard(tester);
    await tapText(tester, 'Get started');

    await tapText(tester, 'Dark');

    expect(prefsOf(tester).get<String>(optionThemeMode), 'dark',
        reason: 'The theme chosen in the onboarding should be the one the app uses');
  });

  testWidgets('Should go back to the color of the system after picking another one', (tester) async {
    await pumpWizard(tester);
    await tapText(tester, 'Get started');
    prefsOf(tester).set(optionThemeColor, 'red');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.wallpaper));
    await tester.pumpAndSettle();

    expect(prefsOf(tester).get<String>(optionThemeColor), 'accent',
        reason: 'The system color is the default, so it should stay one tap away');
  });

  testWidgets('Should hide true black when the light mode is picked', (tester) async {
    await pumpWizard(tester);
    await tapText(tester, 'Get started');
    expect(find.text('True Black?'), findsOneWidget, reason: 'The system mode may be dark, where true black applies');

    await tapText(tester, 'Light');

    expect(find.text('True Black?'), findsNothing, reason: 'True black only changes the dark mode');
  });

  testWidgets('Should warn on a page and not in a popup when the user does not log in', (tester) async {
    await pumpWizard(tester);
    await reachLogin(tester);
    expectNoPopup();

    await tapText(tester, 'Not now');

    expect(find.text('Continue without an account?'), findsOneWidget,
        reason: 'The user should learn what they lose without an account');
    expect(find.textContaining('can only open 𝕏 links'), findsOneWidget,
        reason: 'The warning should say that only X links work without an account');
    expectNoPopup();

    await tapText(tester, 'Continue without an account');
    expect(find.text("You're all set!"), findsOneWidget, reason: 'The user should be free to go on without account');
  });

  testWidgets('Should still let the user log in from the warning', (tester) async {
    final calls = await pumpWizard(tester);
    await reachLogin(tester);
    await tapText(tester, 'Not now');

    await tapText(tester, 'Login');

    expect(calls.logins, 1, reason: 'Changing their mind should open the login');
    expect(find.text('Import from @me'), findsOneWidget, reason: 'Logging in should lead to the subscriptions');
  });

  testWidgets('Should import the subscriptions of the account that logged in', (tester) async {
    final importer = FakeImporter(following: 3);
    await pumpWizard(tester, importer: importer);
    await reachLogin(tester);
    await tapText(tester, 'Login');

    await tapText(tester, 'Import from @me');

    expect(importer.requests, [('me', 3)], reason: 'Every account followed by the logged in user should be imported');
    expect(find.text('3 subscriptions imported'), findsOneWidget, reason: 'The page should say how many were imported');
    expectNoPopup();

    await tapText(tester, 'Next');
    expect(find.text("You're all set!"), findsOneWidget, reason: 'The import should lead to the last step');
  });

  testWidgets('Should import the subscriptions of another account on a step of its own', (tester) async {
    final importer = FakeImporter(following: 2);
    await pumpWizard(tester, importer: importer);
    await reachLogin(tester);
    await tapText(tester, 'Login');
    await tapText(tester, 'Import from another account');
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Import')).onPressed, isNull,
        reason: 'There is no account to import from until a username is typed');

    await tester.enterText(find.byType(TextField), 'someone_else');
    await tester.pump();
    await tapText(tester, 'Import');

    expect(importer.requests, [('someone_else', 2)], reason: 'The typed account should be the one imported');
    expect(find.text('2 subscriptions imported'), findsOneWidget, reason: 'The step should say how many were imported');
    expectNoPopup();
    await tapText(tester, 'Next');
    expect(find.text("You're all set!"), findsOneWidget, reason: 'The import should lead to the last step');
  });

  testWidgets('Should let the user cancel the choice of how many accounts to import', (tester) async {
    final importer = FakeImporter(following: 600, limit: 250);
    await pumpWizard(tester, importer: importer);
    await reachLogin(tester);
    await tapText(tester, 'Login');
    await tapText(tester, 'Import from another account');
    await tester.enterText(find.byType(TextField), 'someone_else');
    await tester.pump();
    await tapText(tester, 'Import');

    await tapText(tester, 'Cancel');

    expect(importer.requests, isEmpty, reason: 'Cancelling should import nothing');
    expect(find.text('Import 250 subscriptions'), findsNothing, reason: 'The choice should be gone');
    expect(find.text('someone_else'), findsOneWidget, reason: 'The username should stay, to be corrected');
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Import')).onPressed, isNotNull,
        reason: 'The user should be able to import again');
  });

  testWidgets('Should show the username again when coming back to a pending choice', (tester) async {
    await pumpWizard(tester, importer: FakeImporter(following: 600, limit: 250));
    await reachLogin(tester);
    await tapText(tester, 'Login');
    await tapText(tester, 'Import from another account');
    await tester.enterText(find.byType(TextField), 'someone_else');
    await tester.pump();
    await tapText(tester, 'Import');

    await tapText(tester, 'Back');
    await tapText(tester, 'Import from another account');

    expect(find.text('someone_else'), findsOneWidget, reason: 'The choice is about this account, so it should show');
    expect(find.text('Cancel'), findsOneWidget, reason: 'The user should be able to get out of the choice');
  });

  testWidgets('Should go back to the two choices from the other account step', (tester) async {
    await pumpWizard(tester);
    await reachLogin(tester);
    await tapText(tester, 'Login');
    await tapText(tester, 'Import from another account');

    await tapText(tester, 'Back');

    expect(find.text('Import from @me'), findsOneWidget, reason: 'Back should offer to import the own account again');
  });

  testWidgets('Should not ask to log in again when coming back after logging in', (tester) async {
    final calls = await pumpWizard(tester);
    await reachLogin(tester);
    await tapText(tester, 'Login');

    await tapText(tester, 'Back');

    expect(find.text("You're logged in"), findsOneWidget,
        reason: 'Logging in again would add sign-ins, which X may take for a bot and lock the account');
    expect(find.textContaining('@me'), findsOneWidget, reason: 'The page should say which account is used');
    expect(find.text('Login'), findsNothing, reason: 'There is nothing to log in to anymore');
    await tapText(tester, 'Next');
    expect(calls.logins, 1, reason: 'Moving on should not open the login again');
    expect(find.text('Import from @me'), findsOneWidget, reason: 'Next should lead back to the subscriptions');
  });

  testWidgets('Should not ask to log in again for an account saved before the app was closed', (tester) async {
    final calls = await pumpWizard(tester, saved: [Account(id: 'csrf', screenName: 'grimace', authHeader: '{}')]);

    await reachLogin(tester);

    expect(find.text("You're logged in"), findsOneWidget,
        reason: 'Logging in again would add sign-ins, which X may take for a bot and lock the account');
    expect(find.textContaining('@grimace'), findsOneWidget, reason: 'The page should say which account is used');
    await tapText(tester, 'Next');
    expect(calls.logins, 0, reason: 'The saved account should be used without opening the login');
    expect(find.text('Import from @grimace'), findsOneWidget, reason: 'The saved account should be offered to import');
  });

  testWidgets('Should only offer another account when the saved one has no username', (tester) async {
    await pumpWizard(tester, saved: [Account(id: 'csrf', screenName: null, authHeader: '{}')]);
    await reachLogin(tester);
    expect(find.textContaining('@'), findsNothing, reason: 'An empty username should not show as a lone @');

    await tapText(tester, 'Next');

    expect(find.text('Import from another account'), findsOneWidget,
        reason: 'Older versions saved some accounts without their username, which is still enough to import');
    expect(find.textContaining('Import from @'), findsNothing, reason: 'There is no username to import from');
  });

  testWidgets('Should let the user log out to log in with another account', (tester) async {
    final calls = await pumpWizard(tester);
    await reachLogin(tester);
    await tapText(tester, 'Login');
    await tapText(tester, 'Back');

    await tapText(tester, 'Log out');

    expect(calls.loggedOut.single.screenName, 'me', reason: 'The account logged in should be removed from QuaX');
    expect(find.text('Log in to 𝕏'), findsOneWidget, reason: 'The user should be able to log in again');
  });

  testWidgets('Should ask on the page how many accounts to import when there are too many', (tester) async {
    final importer = FakeImporter(following: 600, limit: 300);
    await pumpWizard(tester, importer: importer);
    await reachLogin(tester);
    await tapText(tester, 'Login');

    await tapText(tester, 'Import from @me');

    expectNoPopup();
    expect(find.text('Import 600 subscriptions'), findsOneWidget, reason: 'Importing everything should stay possible');
    await tapText(tester, 'Import 300 subscriptions');
    expect(importer.requests, [('me', 300)], reason: 'Only the chosen number of accounts should be imported');
  });

  testWidgets('Should offer a retry when the import fails', (tester) async {
    await pumpWizard(tester, importer: FakeImporter(error: StateError('offline')));
    await reachLogin(tester);
    await tapText(tester, 'Login');

    await tapText(tester, 'Import from @me');

    expect(find.text('Unable to import'), findsOneWidget, reason: 'The failure should be explained on the page');
    await tapText(tester, 'Retry');
    expect(find.text('Import from @me'), findsOneWidget, reason: 'Retrying should offer the import choices again');
  });

  testWidgets('Should go back to the previous step', (tester) async {
    await pumpWizard(tester);
    await reachLogin(tester);

    await tapText(tester, 'Back');

    expect(find.text('Choose your theme'), findsOneWidget, reason: 'Back should return to the theme');
  });

  testWidgets('Should open the Discord invite from the last step', (tester) async {
    final calls = await pumpWizard(tester);
    await tapText(tester, 'Import backup');

    await tapText(tester, 'Join our Discord');

    expect(calls.discord, 1, reason: 'The Discord invite should open');
  });

  testWidgets('Should open the home page and never show again once finished', (tester) async {
    await pumpWizard(tester);
    await tapText(tester, 'Import backup');

    await tapText(tester, 'Finish');

    expect(find.text('Home page'), findsOneWidget, reason: 'Finishing should open the app');
    expect(prefsOf(tester).get<bool>(optionOnboardingDone), isTrue,
        reason: 'The onboarding should only run on the first launch');
    expect(prefsOf(tester).get<bool>(optionDiscordPopupDismissed), isTrue,
        reason: 'The Discord was already offered, so its popup should not show up later');
  });

  group('On every screen', () {
    /// From the theme to the last step
    Future<void> walkThrough(WidgetTester tester) async {
      await tapText(tester, 'Next');
      await tapText(tester, 'Not now');
      await tapText(tester, 'Login');
      await tapText(tester, 'Import from @me');
      await tapText(tester, 'Next');
      expect(find.text("You're all set!"), findsOneWidget, reason: 'Every step should be usable on this screen');
    }

    double centerOf(WidgetTester tester, String text) => tester.getCenter(find.text(text)).dx;

    testWidgets('Should keep one column on a phone held upright', (tester) async {
      await pumpWizard(tester);
      await tapText(tester, 'Get started');

      expect(centerOf(tester, 'Next'), closeTo(1080 / 2.625 / 2, 1),
          reason: 'On a narrow screen, the buttons should take the whole width');
    });

    testWidgets('Should put the explanation beside the content on a phone held sideways', (tester) async {
      await pumpWizard(tester, screen: pixel10Sideways);
      await tapText(tester, 'Get started');

      final width = pixel10Sideways.width / 2.625;
      expect(centerOf(tester, 'Choose your theme'), lessThan(width / 2),
          reason: 'There is little height, so the explanation should go on the left');
      expect(centerOf(tester, 'Next'), greaterThan(width / 2),
          reason: 'The main button should be on the right, where the eye ends up');
      await walkThrough(tester);
    });

    testWidgets('Should keep a readable column on a tablet held upright', (tester) async {
      await pumpWizard(tester, screen: tablet);
      await tapText(tester, 'Get started');

      expect(tester.getSize(find.widgetWithText(FilledButton, 'Next')).width, lessThanOrEqualTo(600),
          reason: 'A button across the whole width of a tablet would be hard to read and to reach');
      await walkThrough(tester);
    });

    testWidgets('Should work on a tablet held sideways', (tester) async {
      await pumpWizard(tester, screen: tabletSideways);
      await tapText(tester, 'Get started');
      await walkThrough(tester);
    });
  });
}
