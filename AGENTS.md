# AGENTS.md — Portal del paciente (Flutter web)

Guía obligatoria para cualquier agente o persona que modifique este repo. Este front es **el portal público del
paciente**; el sistema del personal vive en `../frontend-angular`. Ambos deben verse y comportarse como un solo producto.

## Reglas de oro

1. **No se toca el backend** (`../MedicalBooking-AD-Backend`). El contrato es `docs/api/openapi.json`. Si falta algo, se documenta como brecha (ver abajo), no se inventa.
2. **Idioma**: la interfaz en español; código, identificadores, comentarios y commits en inglés.
3. **Mismas guías de estilo que Angular**: paleta naranja, tipografía, componentes y arquitectura equivalentes. Si cambias un token aquí, cámbialo también en `../frontend-angular/src/styles.scss` (y viceversa). Tokens en `lib/core/design/tokens.dart`.
4. **Paridad de comportamiento**: mismos tipos de error, mismo manejo de 401, mismos textos para el mismo caso (ver "Errores").
5. No guardes secretos ni tokens en URLs, logs ni código. Las credenciales de demo viven solo en `infrastructure/demo`.

## Arquitectura

Feature-first (screaming) con Clean Architecture dentro de cada feature. La dependencia apunta hacia adentro:
`presentation -> domain <- data`.

```
lib/app/            raíz de composición (dependencies.dart), router, scope, shell
lib/core/           tokens, theme, http (ApiClient), errores, tiempo (sucursal UTC-5), formato
lib/shared/         atoms / molecules / organisms reutilizables
lib/infrastructure/ base de datos demo en memoria
lib/features/<f>/{domain,data,presentation}
```

- `domain`: entidades, puertos (repositorios abstractos), casos de uso. Dart puro: sin Flutter, sin `http`.
- `data`: implementaciones `demo_*` y `http_*` de los puertos. Aquí se traducen los DTOs del backend (español, snake_case) a entidades en inglés.
- `presentation`: páginas = contenedores (obtienen datos vía controladores/casos de uso); widgets = presentacionales (solo reciben datos y callbacks).
- **Única raíz de composición**: `lib/app/dependencies.dart` (`AppDependencies.demo()` y `.api()`). Nadie más instancia repositorios concretos.
- Estado con `ChangeNotifier` (controladores). Acceso por `AppScope`.

## Modos demo y API

- Demo (por defecto): datos en memoria, sin red.
- API: `--dart-define=API_BASE_URL=/api/v1` (y `SERVICES_JSON` con los servicios reservables reales). Se sirve con `node tools/serve_web.mjs` (proxy `/api` → backend, sin CORS).
- Una funcionalidad nueva se implementa **en ambos modos** (repositorio `demo_*` y `http_*`) detrás del mismo puerto.

## Contrato con el backend

- Errores `application/problem+json` con `correlation_id`: se mapean a `ErrorKind` (`lib/core/domain/app_error.dart`). Muestra el `correlation_id` como código de soporte.
- JWT HS256 de 15 min, sin refresh ni revocación: al vencer o recibir 401 con token, la sesión termina como "expirada" y se vuelve a `/login?motivo=expirada`.
- `POST /appointments` lleva `Idempotency-Key` (`newIdempotencyKey()`). 409 → horario tomado.
- Fechas en UTC en la API; la sucursal está en UTC-5 (helpers en `core/time`).
- Roles y permisos solo mejoran la UX; la autorización real es del backend. Cuenta que no sea `PACIENTE` → `ErrorKind.notPatient`.

### Brechas conocidas del backend (no inventar datos)

| Falta | Qué hace el portal |
| --- | --- |
| Listados "mis citas" / "mis órdenes" | Muestra las citas reservadas en la sesión; las órdenes se consultan por id |
| Endpoints de catálogo | Catálogo estático; servicios desde `SERVICES_JSON` |
| Confirmación de pago | No se muestra |
| `/me` solo trae id, roles y permisos | Se muestra el correo |
| Orden sin fechas/médico/nombre de pruebas | Campos opcionales; pruebas como "Prueba N" |

Si el backend cierra una brecha, actualiza el repositorio `http_*`, quita la limitación de esta tabla y del README.

## Errores (paridad con Angular)

`invalidCredentials, unauthenticated, forbidden, notFound, conflict, validation, rateLimited, network, unavailable (502/503/504), notPatient, unknown`.
Los textos en español salen de `describeError` (`shared/presentation/error_message.dart`); no escribas mensajes sueltos en las páginas.

## Seguridad

- Sesión en `sessionStorage` (clave `medilo.patient.session`), nunca `localStorage`.
- Redirecciones post-login solo a rutas internas (`safeNext`); jamás a URLs externas.
- Hay un hook que bloquea escribir contraseñas literales: usa valores aleatorios o variables en mocks y tests.

## Definición de terminado

1. `flutter analyze` sin issues.
2. `flutter test` en verde (incluye `test/app/api_mode_flow_test.dart` con `MockClient`).
3. `flutter build web` (y con `--dart-define=API_BASE_URL=/api/v1`) compila.
4. Para cambios visuales o de flujo: revisar en navegador, también en ancho móvil.
5. **Sé honesto**: si solo verificaste contra un mock del contrato, dilo; no afirmes que funciona contra el backend real.
6. Pruebas nuevas: una por regla; pasan por la interfaz pública. Los overflows de la fuente Ahem en tests se filtran como en `app_flow_test.dart`.

## Git

- Ramas `feat/…`, `fix/…`; commits Conventional Commits en inglés, **sin** atribución a IA.
- PR hacia `develop` con descripción en español. No hagas push ni abras PR sin que te lo pidan.

## Checklist de paridad con Angular

- [ ] Tokens de diseño idénticos
- [ ] Mismos `ErrorKind` y textos
- [ ] Mismo manejo de 401/expiración
- [ ] Mismas capas y nombres de feature
- [ ] Mismas brechas documentadas en ambos README
