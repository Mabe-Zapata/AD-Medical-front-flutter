import 'package:flutter/widgets.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';

/// Exposes [AppDependencies] to the widget tree. The dependencies never change,
/// so reading them does not register a rebuild dependency (safe in initState).
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
