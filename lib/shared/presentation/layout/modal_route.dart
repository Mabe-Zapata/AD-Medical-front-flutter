import 'package:flutter/material.dart';

/// A page shown as a modal over the previous one. It is a normal named route, so the browser's back
/// button and deep links keep working, and the page underneath stays visible.
Route<T> modalRoute<T>({required RouteSettings settings, required WidgetBuilder builder}) => RawDialogRoute<T>(
  settings: settings,
  barrierDismissible: true,
  barrierLabel: 'Cerrar',
  barrierColor: Colors.black.withValues(alpha: 0.55),
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (context, _, _) => builder(context),
  transitionBuilder: (context, animation, _, child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  },
);
