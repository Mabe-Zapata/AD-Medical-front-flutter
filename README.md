# Medilo patient portal (Flutter web)

Public portal for patients of the clinical laboratory platform: general lab information,
appointment booking and access to validated results. The UI is in Spanish, the code in English.

The app currently runs on an in-memory demo API (`lib/infrastructure/demo`), shaped like the
backend schema (`citas`, `horarios_disponibles`, `ordenes_laboratorio`, `resultados_laboratorio`...).

## Run

```bash
flutter pub get
flutter run -d chrome        # or: flutter run -d web-server --web-port 8765
flutter test
flutter analyze
```

Demo account: `paciente@demo.test` / `demo1234`.

## Architecture

Feature-first (screaming) with Clean Architecture layers inside each feature.
Dependencies point inwards: `presentation -> domain <- data`.

```
lib/
  app/             composition root (dependencies.dart), router, scope, app shell
  core/            design tokens, theme, time (branch UTC-5) and Spanish formatting
  shared/          atoms / molecules / organisms reused across features
  infrastructure/  demo in-memory database (replace with the REST client)
  features/
    auth/  catalog/  booking/  lab_results/  portal/
      domain/        entities, repository ports, use cases (pure Dart)
      data/          repository implementations
      presentation/  pages (containers), widgets (presentational), controllers
```

To connect the real API, add repositories that implement the ports in each `domain/repositories`
and swap them in `AppDependencies` (`lib/app/dependencies.dart`).
