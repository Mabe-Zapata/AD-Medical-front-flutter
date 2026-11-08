# Medilo patient portal (Flutter web)

Public portal for patients of the clinical laboratory platform: general lab information,
appointment booking and access to validated results. The UI is in Spanish, the code in English.

Sibling of the Angular staff system (`../frontend-angular`). Read [AGENTS.md](AGENTS.md) before changing anything.

## Two modes, one codebase

| Mode | How | Data |
| --- | --- | --- |
| Demo (default) | `flutter run -d chrome` | In-memory database shaped like the backend schema. Account `paciente@demo.test` / `demo1234`. |
| API | `--dart-define=API_BASE_URL=/api/v1` | The real REST API: login, availability, reservations, cancel, lab results. |

Accounts of a backend with migration `0007` (pending merge, `APP_ENV` other than production): `paciente1@test.com` / `Password1`.

Only `lib/app/dependencies.dart` knows which repositories are wired; use cases, controllers and pages are shared.

## Run

```bash
flutter pub get
flutter test
flutter analyze

# Demo (port 8081, the one FLUTTER_FRONT_URL points to)
flutter run -d chrome --web-port 8081

# API: build, then serve build/web and proxy /api to the backend (no CORS needed)
flutter build web --dart-define=API_BASE_URL=/api/v1
node tools/serve_web.mjs 4300          # BACKEND_URL defaults to http://localhost:5000
```

On Windows with Git Bash, prefix the build with `MSYS_NO_PATHCONV=1`: otherwise `/api/v1` is rewritten into a
`C:/Program Files/Git/...` path and every request fails with "No se pudo conectar con el servidor".

Build-time settings (`--dart-define`):

| Name | Meaning |
| --- | --- |
| `API_BASE_URL` | Absolute or origin-relative API root. Empty means demo mode. |
| `SERVICES_JSON` | Bookable services of the environment: `[{"id":"<uuid>","name":"...","durationMin":20,"basePrice":8}]`. Without it the demo services are used and a real reservation is refused (their ids are not UUIDs of that backend). |

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
  core/            design tokens, theme, http client, errors, time (branch UTC-5), Spanish formatting
  shared/          atoms / molecules / organisms reused across features
  infrastructure/  demo in-memory database
  features/
    auth/  catalog/  booking/  lab_results/  portal/
      domain/        entities, repository ports, use cases (pure Dart)
      data/          demo_* and http_* repository implementations
      presentation/  pages (containers), widgets (presentational), controllers
```

## What the backend does not offer yet

The portal degrades gracefully instead of inventing data:

| Gap | Behavior in API mode |
| --- | --- |
| No "my appointments" / "my orders" listing | Appointments reserved in this session are shown; orders are opened by id (lookup form). |
| No catalog endpoints | Static catalog; services come from `SERVICES_JSON`. |
| No payment confirmation | Not shown. |
| `/me` returns only id, roles, permissions | The patient is shown by email. |
| Order response lacks dates, doctor and test names | Optional fields; tests are labeled "Prueba N". |
| No resend of the activation email, no phone at sign-up | The link expires after 24 h and cannot be requested again; the phone is not asked. |

## Quality bar

`flutter analyze` clean, `flutter test` green, `flutter build web` succeeds. API-mode flows are verified
against a contract mock (`MockClient`), not a live backend: say so when reporting.
