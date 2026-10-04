import 'dart:math';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:pref/pref.dart';
import 'package:quax/constants.dart';
import 'package:quax/onboarding/_page.dart';

/// Draws a phone, drops the user's data into it and locks it: everything stays on the device.
class OnDeviceAnimation extends StatefulWidget {
  /// How long the drawing takes, so that what comes after it can wait for it to end
  static const duration = Duration(milliseconds: 3400);

  /// Shows the end of the drawing at once, such as when it was seen already
  final bool skip;

  final VoidCallback? onPlayed;

  const OnDeviceAnimation({super.key, this.skip = false, this.onPlayed});

  @override
  State<OnDeviceAnimation> createState() => _OnDeviceAnimationState();
}

class _OnDeviceAnimationState extends State<OnDeviceAnimation> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: OnDeviceAnimation.duration);

  static const _data = [Icons.group, Icons.favorite, Icons.bookmark];

  @override
  void initState() {
    super.initState();
    final disabled = PrefService.of(context, listen: false).get<bool>(optionDisableAnimations) ?? false;
    if (disabled || widget.skip) {
      _controller.value = 1;
    } else {
      _controller.forward().then((_) => widget.onPlayed?.call());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, [Curve curve = Curves.easeInOut]) => CurvedAnimation(
    parent: _controller,
    curve: Interval(begin, end, curve: curve),
  );

  Widget _droppedIcon(int index, Color color) {
    final start = 0.46 + index * 0.08;
    final progress = _interval(start, start + 0.14, Curves.easeOutBack);
    final top = lerpDouble(-40, 52.0 + index * 40, progress.value)!;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: _interval(start, start + 0.1).value,
        child: Icon(_data[index], size: 30, color: color),
      ),
    );
  }

  Widget _lock(ColorScheme colors) {
    return Positioned(
      right: 62,
      bottom: 0,
      child: Opacity(
        opacity: _interval(0.74, 0.86).value,
        child: Transform.scale(
          scale: _interval(0.74, 1, Curves.easeOutBack).value,
          child: CircleAvatar(
            radius: 26,
            backgroundColor: colors.primaryContainer,
            child: Icon(Icons.lock, size: 28, color: colors.onPrimaryContainer),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Smaller on a short screen, such as a phone held sideways, so that it leaves room for the text
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = min(230.0, screenHeight * (OnboardingPage.isShort(context) ? 0.25 : 0.35));
    return Center(
      child: SizedBox(
        height: maxHeight,
        child: FittedBox(
          child: SizedBox(
            width: 260,
            height: 230,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PhonePainter(
                        outline: _interval(0, 0.4).value,
                        homeIndicator: _interval(0.38, 0.48, Curves.easeOut).value,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  ...List.generate(_data.length, (index) => _droppedIcon(index, colors.secondary)),
                  _lock(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A phone whose [outline] is drawn up to its progress, then whose [homeIndicator] grows from its center.
class _PhonePainter extends CustomPainter {
  final double outline;
  final double homeIndicator;
  final Color color;

  const _PhonePainter({required this.outline, required this.homeIndicator, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final phone = Rect.fromCenter(center: size.center(Offset.zero), width: 120, height: 200);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final body = (Path()..addRRect(RRect.fromRectAndRadius(phone, const Radius.circular(22)))).computeMetrics().first;
    canvas.drawPath(body.extractPath(0, body.length * outline), paint);

    // Nothing at all before it grows, or the round cap would leave a dot
    if (homeIndicator > 0) {
      final halfWidth = 18 * homeIndicator;
      final y = phone.bottom - 14;
      canvas.drawLine(Offset(phone.center.dx - halfWidth, y), Offset(phone.center.dx + halfWidth, y), paint);
    }
  }

  @override
  bool shouldRepaint(_PhonePainter old) =>
      old.outline != outline || old.homeIndicator != homeIndicator || old.color != color;
}
