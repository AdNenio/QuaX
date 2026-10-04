import 'package:material_ui/material_ui.dart';
import 'package:pref/pref.dart';
import 'package:quax/constants.dart';

/// Fades [child] in while it rises into place, after [delay]. It is shown at once when [skip], such as when it was
/// seen already.
class Entrance extends StatefulWidget {
  final Duration delay;
  final bool skip;
  final Widget child;

  const Entrance({super.key, required this.delay, this.skip = false, required this.child});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 800);

  late final _controller = AnimationController(vsync: this, duration: widget.delay + _duration);
  late final _animation = CurvedAnimation(
    parent: _controller,
    curve: Interval(widget.delay.inMilliseconds / _controller.duration!.inMilliseconds, 1, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    final disabled = PrefService.of(context, listen: false).get<bool>(optionDisableAnimations) ?? false;
    disabled || widget.skip ? _controller.value = 1 : _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(_animation),
        child: widget.child,
      ),
    );
  }
}
