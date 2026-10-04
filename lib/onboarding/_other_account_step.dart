import 'package:flutter_triple/flutter_triple.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quax/generated/l10n.dart';
import 'package:quax/onboarding/_import_progress.dart';
import 'package:quax/onboarding/_page.dart';
import 'package:quax/onboarding/onboarding_model.dart';
import 'package:quax/subscriptions/_import.dart';

/// Imports the subscriptions of any X account, whose username the user types.
class OtherAccountStep extends StatefulWidget {
  final OnboardingModel model;
  final SubscriptionImportModel importModel;

  const OtherAccountStep({super.key, required this.model, required this.importModel});

  @override
  State<OtherAccountStep> createState() => _OtherAccountStepState();
}

class _OtherAccountStepState extends State<OtherAccountStep> {
  // Back on this step with a choice still pending, the username it is about is shown again
  late final _username = ValueNotifier(switch (widget.importModel.state) {
    ImportTooLarge(screenName: final screenName) => screenName,
    _ => '',
  });

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  void _import() {
    if (_username.value.isNotEmpty) {
      widget.importModel.prepare(_username.value);
    }
  }

  Widget _action(L10n l10n, Triple<SubscriptionImportProgress> triple) {
    if (triple.state is ImportFinished) {
      return FilledButton(onPressed: () => widget.model.goTo(OnboardingStep.community), child: Text(l10n.next));
    }
    final canImport = triple.state is ImportNotStarted && !importRunning(triple) && triple.error == null;
    return ValueListenableBuilder(
      valueListenable: _username,
      builder: (context, username, _) =>
          FilledButton(onPressed: canImport && username.isNotEmpty ? _import : null, child: Text(l10n.import)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return TripleBuilder<SubscriptionImportModel, SubscriptionImportProgress>(
      store: widget.importModel,
      builder: (context, triple) {
        final editable = triple.state is ImportNotStarted && !importRunning(triple);
        return OnboardingPage(
          model: widget.model,
          busy: importRunning(triple),
          icon: const Icon(Icons.person_search),
          title: l10n.onboarding_import_from_another_account,
          text: l10n.import_subscriptions_intro,
          content: [
            ImportUsernameField(
                initialValue: _username.value,
                enabled: editable,
                onChanged: (value) => _username.value = value,
                onSubmitted: (_) => _import()),
            const SizedBox(height: 16),
            ...?importProgress(context, triple, widget.importModel),
          ],
          actions: [_action(l10n, triple)],
        );
      },
    );
  }
}
