import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/core/config/app_settings.dart';
import 'package:medicalbooking_portal/features/catalog/data/services_json.dart';

/// Without `--dart-define=API_BASE_URL=...` the app runs on the in-memory demo.
void main() {
  final dependencies = BuildSettings.apiBaseUrl.isEmpty
      ? AppDependencies.demo()
      : AppDependencies.api(
          apiBaseUrl: BuildSettings.apiBaseUrl,
          services: parseServices(BuildSettings.servicesJson),
        );
  runApp(MedicalBookingApp(dependencies: dependencies));
}
