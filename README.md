# Medilo patient portal (Flutter web)

Public portal for patients of the clinical laboratory platform: general lab information,
appointment booking and access to validated results. The UI is in Spanish, the code in English.

The app currently runs on an in-memory demo API (`lib/infrastructure/demo`), shaped like the
backend schema (`citas`, `horarios_disponibles`, `ordenes_laboratorio`, `resultados_laboratorio`...).

## Run

```bash
flutter pub get
flutter run -d chrome --web-port 8081
flutter test
flutter analyze
```

Demo account: `paciente@demo.test` / `demo1234`.

## Ports and URLs

| Piece | URL (local) | Where it is set |
| --- | --- | --- |
| Patient portal (Flutter web) | `http://localhost:8081` | `flutter run -d chrome --web-port 8081` |
| Staff system (Angular) | `http://localhost:4200` | `ng serve` default |
| Backend API (Flask) | `http://localhost:5000` | `flask --app medicalbooking.app:create_app run --port 5000` |

The backend builds links in emails from these variables in its `.env`:

```dotenv
FLUTTER_FRONT_URL=http://localhost:8081
ANGULAR_FRONT_URL=http://localhost:4200
```

`FLUTTER_FRONT_URL` must match the address where this portal is served. In production, set it to the
public portal URL (https). Port 8080 is taken on the development machine, so the portal uses 8081.

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
