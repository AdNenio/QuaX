import 'package:flutter_triple/flutter_triple.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quax/generated/l10n.dart';
import 'package:quax/onboarding/_import_progress.dart';
import 'package:quax/onboarding/_page.dart';
import 'package:quax/onboarding/onboarding_model.dart';

class SubscriptionsStep extends StatelessWidget {
  final OnboardingModel model;
  final SubscriptionImportModel importModel;

  /// The username of the account QuaX uses, unknown for some accounts saved by older versions
  final String? screenName;

  const SubscriptionsStep({super.key, required this.model, required this.importModel, this.screenName});

  List<Widget> _choices(L10n l10n, String? screenName) => [
        if (screenName != null)
          OnboardingChoice(
            icon: Icons.person,
            title: l10n.onboarding_import_from(screenName),
            onTap: () => importModel.prepare(screenName),
          ),
        OnboardingChoice(
          icon: Icons.person_search,
          title: l10n.onboarding_import_from_another_account,
          onTap: () => model.goTo(OnboardingStep.otherAccount),
        ),
      ];

  Widget _next(L10n l10n, Triple<SubscriptionImportProgress> triple) {
    void next() => model.goTo(OnboardingStep.community);
    return triple.state is ImportFinished
        ? FilledButton(onPressed: next, child: Text(l10n.next))
        : FilledButton.tonal(onPressed: importRunning(triple) ? null : next, child: Text(l10n.skip));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return TripleBuilder<SubscriptionImportModel, SubscriptionImportProgress>(
      store: importModel,
      builder: (context, triple) {
        return OnboardingPage(
          model: model,
          busy: importRunning(triple),
          icon: const Icon(Icons.group_add),
          title: l10n.import_subscriptions,
          text: l10n.onboarding_import_text,
          content: importProgress(context, triple, importModel) ?? _choices(l10n, screenName),
          actions: [_next(l10n, triple)],
        );
      },
    );
  }
}
