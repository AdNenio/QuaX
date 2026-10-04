import 'package:material_ui/material_ui.dart';
import 'package:quax/database/entities.dart';
import 'package:quax/generated/l10n.dart';
import 'package:quax/onboarding/_entrance.dart';
import 'package:quax/onboarding/_on_device_animation.dart';
import 'package:quax/onboarding/_page.dart';
import 'package:quax/onboarding/onboarding_model.dart';
import 'package:quax/onboarding/_theme_picker.dart';
import 'package:quax/ui/errors.dart';

class WelcomeStep extends StatelessWidget {
  final OnboardingModel model;
  final Future<bool> Function() importBackup;

  const WelcomeStep({super.key, required this.model, required this.importBackup});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return OnboardingPage(
      model: model,
      busy: model.isLoading,
      icon: const _QuaxLogo(),
      title: l10n.onboarding_welcome_title,
      illustration: Column(children: [
        OnDeviceAnimation(skip: model.state.welcomePlayed, onPlayed: model.playedWelcome),
        const SizedBox(height: 16),
        // One after the other once the drawing is over, in the order they are read
        Entrance(
          delay: OnDeviceAnimation.duration,
          skip: model.state.welcomePlayed,
          child: Text(l10n.onboarding_welcome_text,
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 24),
      ]),
      content: [
        if (model.error != null)
          ErrorCard(error: model.error, stackTrace: null, prefix: (l10n) => l10n.unable_to_import),
        Entrance(
          delay: OnDeviceAnimation.duration + const Duration(milliseconds: 600),
          skip: model.state.welcomePlayed,
          child: OnboardingChoice(
            icon: Icons.auto_awesome,
            title: l10n.onboarding_start_fresh,
            subtitle: l10n.onboarding_start_fresh_description,
            onTap: model.isLoading ? null : () => model.goTo(OnboardingStep.theme),
          ),
        ),
        Entrance(
          delay: OnDeviceAnimation.duration + const Duration(milliseconds: 800),
          skip: model.state.welcomePlayed,
          child: OnboardingChoice(
            icon: Icons.settings_backup_restore,
            title: l10n.import_backup,
            subtitle: l10n.onboarding_backup_description,
            onTap: model.isLoading ? null : () => model.importBackup(importBackup),
          ),
        ),
      ],
    );
  }
}

/// The Q of the app icon, in the color of the other icons of the onboarding
class _QuaxLogo extends StatelessWidget {
  const _QuaxLogo();

  @override
  Widget build(BuildContext context) {
    // Fills the tile: the Android monochrome icon leaves a third of margin around the Q, like an icon would
    return Image.asset('assets/icon-monochrome-432x432.png',
        color: IconTheme.of(context).color, colorBlendMode: BlendMode.srcIn);
  }
}

class ThemeStep extends StatelessWidget {
  final OnboardingModel model;

  const ThemeStep({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return OnboardingPage(
      model: model,
      icon: const Icon(Icons.palette),
      title: l10n.onboarding_theme_title,
      text: l10n.onboarding_theme_text,
      content: [
        const ThemePicker(),
      ],
      actions: [FilledButton(onPressed: () => model.goTo(OnboardingStep.login), child: Text(l10n.next))],
    );
  }
}

class LoginStep extends StatelessWidget {
  final OnboardingModel model;
  final Future<Account?> Function() logIn;
  final Future<void> Function(Account account) logOut;

  const LoginStep({super.key, required this.model, required this.logIn, required this.logOut});

  @override
  Widget build(BuildContext context) {
    final account = model.state.account;
    // Logging in again would only add sign-ins, which X may take for a bot and lock the account
    return account == null ? _loggedOut(context) : _loggedIn(context, account);
  }

  Widget _loggedOut(BuildContext context) {
    final l10n = L10n.of(context);
    return OnboardingPage(
      model: model,
      busy: model.isLoading,
      icon: const Icon(Icons.account_circle),
      title: l10n.onboarding_login_title,
      text: l10n.onboarding_login_text,
      content: [
        if (model.error != null) ErrorCard(error: model.error, stackTrace: null, prefix: (l10n) => l10n.login),
        Card.filled(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            shape: const Border(),
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.onboarding_login_details),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [Text(l10n.logging_in_quax_information)],
          ),
        ),
      ],
      actions: [
        FilledButton(onPressed: model.isLoading ? null : () => model.logIn(logIn), child: Text(l10n.login)),
        FilledButton.tonal(
            onPressed: model.isLoading ? null : () => model.goTo(OnboardingStep.noAccount),
            child: Text(l10n.onboarding_not_now)),
      ],
    );
  }

  Widget _loggedIn(BuildContext context, Account account) {
    final l10n = L10n.of(context);
    return OnboardingPage(
      model: model,
      busy: model.isLoading,
      icon: const Icon(Icons.how_to_reg),
      title: l10n.onboarding_logged_in_title,
      text: switch (account.screenName) {
        final screenName? => l10n.onboarding_logged_in_text(screenName),
        null => null,
      },
      content: [
        if (model.error != null) ErrorCard(error: model.error, stackTrace: null, prefix: (l10n) => l10n.log_out),
      ],
      actions: [
        FilledButton(
            onPressed: model.isLoading ? null : () => model.goTo(OnboardingStep.subscriptions),
            child: Text(l10n.next)),
        FilledButton.tonal(
            onPressed: model.isLoading ? null : () => model.logOut(logOut), child: Text(l10n.log_out)),
      ],
    );
  }
}

class NoAccountStep extends StatelessWidget {
  final OnboardingModel model;
  final Future<Account?> Function() logIn;

  const NoAccountStep({super.key, required this.model, required this.logIn});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return OnboardingPage(
      model: model,
      busy: model.isLoading,
      icon: const Icon(Icons.warning_amber),
      title: l10n.onboarding_no_account_title,
      text: l10n.onboarding_no_account_text,
      content: [
        if (model.error != null) ErrorCard(error: model.error, stackTrace: null, prefix: (l10n) => l10n.login),
      ],
      actions: [
        FilledButton(onPressed: model.isLoading ? null : () => model.logIn(logIn), child: Text(l10n.login)),
        FilledButton.tonal(
            onPressed: model.isLoading ? null : () => model.goTo(OnboardingStep.community),
            child: Text(l10n.onboarding_continue_without_account)),
      ],
    );
  }
}

class CommunityStep extends StatelessWidget {
  final OnboardingModel model;
  final Future<void> Function() joinDiscord;
  final VoidCallback onFinish;

  const CommunityStep({super.key, required this.model, required this.joinDiscord, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return OnboardingPage(
      model: model,
      icon: const Icon(Icons.check_circle),
      title: l10n.onboarding_all_set_title,
      text: l10n.discord_popup_message,
      content: [
        OnboardingChoice(
          icon: Icons.forum,
          title: l10n.join_our_discord,
          onTap: joinDiscord,
        ),
      ],
      actions: [FilledButton(onPressed: onFinish, child: Text(l10n.finish))],
    );
  }
}
