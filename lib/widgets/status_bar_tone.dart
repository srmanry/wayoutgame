import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gives the status bar icons the tone that reads on [background].
class StatusBarTone extends StatelessWidget {
  const StatusBarTone({
    super.key,
    required this.background,
    required this.child,
  });

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value:
        (ThemeData.estimateBrightnessForColor(background) == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
    child: child,
  );
}
