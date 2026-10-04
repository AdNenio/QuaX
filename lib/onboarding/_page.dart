import 'package:material_ui/material_ui.dart';
import 'package:quax/generated/l10n.dart';
import 'package:quax/onboarding/onboarding_model.dart';

/// One step of the onboarding: its explanation, then [content] and the buttons to move on.
///
/// On a phone held upright, everything is in one column with a full-width button per row. On a wider screen held
/// sideways, the explanation goes on the left and the content on the right, with the buttons on one row, as there is
/// little height. A tablet held upright keeps one column, not wider than [_maxColumnWidth].
class OnboardingPage extends StatelessWidget {
  static const _maxColumnWidth = 600.0;
  static const _maxWidth = 1200.0;

  final OnboardingModel model;
  final Widget icon;
  final String title;
  final String? text;

  /// Shown under the explanation, such as a drawing
  final Widget? illustration;
  final List<Widget> content;
  final List<Widget> actions;
  final bool busy;

  const OnboardingPage({
    super.key,
    required this.model,
    required this.icon,
    required this.title,
    this.text,
    this.illustration,
    this.content = const [],
    this.actions = const [],
    this.busy = false,
  });

  /// Shown only while the step waits for something, at the same height as the space it takes otherwise
  Widget _progress() {
    // ignore: deprecated_member_use
    return busy ? const LinearProgressIndicator(year2023: false) : const SizedBox(height: 4);
  }

  /// Whether the screen is short, such as a phone held sideways, where the header has to leave room for the rest
  static bool isShort(BuildContext context) => MediaQuery.sizeOf(context).height < 500;

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final short = isShort(context);
    final tile = short ? 52.0 : 72.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: tile,
          height: tile,
          decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(tile / 3)),
          child: IconTheme.merge(data: IconThemeData(size: tile / 2, color: colors.onPrimaryContainer), child: icon),
        ),
        SizedBox(height: short ? 12 : 24),
        Text(title,
            style: (short ? theme.textTheme.headlineMedium : theme.textTheme.headlineLarge)
                ?.copyWith(color: colors.onSurface)),
        if (text != null) ...[
          const SizedBox(height: 12),
          Text(text!, style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
        ],
        SizedBox(height: short ? 16 : 24),
      ],
    );
  }

  Widget? _back(BuildContext context) => model.state.canGoBack
      ? TextButton(onPressed: busy ? null : model.back, child: Text(L10n.of(context).back))
      : null;

  Widget _stackedButtons(BuildContext context) {
    final tall = ButtonStyle(minimumSize: WidgetStateProperty.all(const Size.fromHeight(56)));
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: FilledButtonTheme(
        data: FilledButtonThemeData(style: tall),
        child: TextButtonTheme(
          data: TextButtonThemeData(style: tall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [...actions, ?_back(context)],
          ),
        ),
      ),
    );
  }

  /// Back at the start, then the actions with the main one at the end, where the eye ends up. They go on two lines
  /// when they don't fit on one.
  Widget _buttonRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, spacing: 8, children: [
        ?_back(context),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: actions.reversed.toList(),
          ),
        ),
      ]),
    );
  }

  Widget _scrolling(BuildContext context, List<Widget> children) => ListView(
      padding: EdgeInsets.fromLTRB(24, isShort(context) ? 16 : 32, 24, isShort(context) ? 16 : 24), children: children);

  Widget _oneColumn(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxColumnWidth),
        child: Column(
          children: [
            _progress(),
            Expanded(child: _scrolling(context, [_header(context), ?illustration, ...content])),
            _stackedButtons(context),
          ],
        ),
      ),
    );
  }

  /// The buttons run under both sides, like in the Android setup wizard, so that long ones still fit on one row
  Widget _sideBySide(BuildContext context) {
    return Column(children: [
      _progress(),
      Expanded(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(children: [
              Expanded(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _scrolling(context, [_header(context), ?illustration])),
                  Expanded(child: _scrolling(context, content)),
                ]),
              ),
              _buttonRow(context),
            ]),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= _maxColumnWidth && constraints.maxWidth > constraints.maxHeight
              ? _sideBySide(context)
              : _oneColumn(context),
        ),
      ),
    );
  }
}

/// A large option to pick, standing out more than a button.
class OnboardingChoice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const OnboardingChoice({super.key, required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: colors.secondaryContainer,
          child: Icon(icon, color: colors.onSecondaryContainer),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: colors.onSurfaceVariant)),
        trailing: const Icon(Icons.arrow_forward),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
