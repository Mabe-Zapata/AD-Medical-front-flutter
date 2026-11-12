# AGENTS.md — Portal del paciente (Flutter web)

Guía obligatoria para cualquier agente o persona que modifique este repo. Este front es **el portal público del
paciente**; el sistema del personal vive en `../frontend-angular`. Ambos deben verse y comportarse como un solo producto.

## Reglas de oro

1. **No se toca el backend** (`../MedicalBooking-AD-Backend`). El contrato es `docs/api/openapi.json`. Si falta algo, se documenta como brecha (ver abajo), no se inventa.
2. **Idioma**: la interfaz en español; código, identificadores, comentarios y commits en inglés.
3. **Mismas guías de estilo que Angular**: paleta naranja, tipografía, componentes y arquitectura equivalentes. Si cambias un token aquí, cámbialo también en `../frontend-angular/src/styles.scss` (y viceversa). Tokens en `lib/core/design/tokens.dart`.
4. **Paridad de comportamiento**: mismos tipos de error, mismo manejo de 401, mismos textos para el mismo caso (ver "Errores").
5. No guardes secretos ni tokens en URLs, logs ni código. Las credenciales de demo viven solo en `infrastructure/demo`.
6. **Contraste AA**: todo texto debe cumplir WCAG AA (4.5:1). Los tokens naranja, verde y ámbar ya están calibrados (`test/core/design/contrast_test.dart`); no los aclares ni uses `slate400` o menos para texto.

## Diseño y experiencia (heurísticas de Nielsen)

- Paleta: naranja de marca + **azul** (`Tokens.blue`, `blueDeep`, `blueText`, `blueSoft`, `blueTint`, ya con contraste AA fijado en `contrast_test.dart`). El azul es para información, acciones secundarias y paneles tranquilos; el naranja, para la acción principal.
- **Listas y tablas**: paginación controlable, por defecto de **5** filas (`PaginationBar`, `pageOf`; opciones 5, 10 y 20). Se oculta si todo cabe en 5.
- **Mensajes**: amigables y accionables; **nunca códigos de soporte ni ids técnicos** (viven en los logs). Todo fallo de una lista ofrece "Reintentar"; todo estado vacío dice qué hacer después.
- Control y prevención: confirmación antes de cancelar, quitar una tarjeta o pagar; botones desactivados mientras algo está en curso; filtros por estado en las citas.

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
- En Windows con Git Bash compila con `MSYS_NO_PATHCONV=1`; si no, `/api/v1` se convierte en una ruta de Windows y todo falla con "No se pudo conectar".
- Una funcionalidad nueva se implementa **en ambos modos** (repositorio `demo_*` y `http_*`) detrás del mismo puerto.

## Contrato con el backend

- Errores `application/problem+json` con `correlation_id`: se mapean a `ErrorKind` (`lib/core/domain/app_error.dart`). Muestra el `correlation_id` como código de soporte.
- JWT HS256 de 15 min, sin refresh ni revocación: al vencer o recibir 401 con token, la sesión termina como "expirada": el portal vuelve a la página de inicio y abre el modal "Tu sesión se cerró" (`/sesion-expirada`, `SessionExpiredDialog`) con "Iniciar sesión" e "Ir al inicio".
- `POST /appointments` lleva `Idempotency-Key` (`newIdempotencyKey()`). 409 → horario tomado.
- Fechas en UTC en la API; la sucursal está en UTC-5 (helpers en `core/time`).
- Roles y permisos solo mejoran la UX; la autorización real es del backend. Cuenta que no sea `PACIENTE` → `ErrorKind.notPatient`.

### Brechas conocidas del backend (no inventar datos)

| Falta | Qué hace el portal |
| --- | --- |
| `GET /appointments` no trae servicio, precio ni motivo | Las citas de visitas anteriores se muestran como "Cita de laboratorio" sin precio; las reservadas en esta sesión conservan sus datos |
| Endpoints de catálogo | Catálogo estático; servicios desde `SERVICES_JSON` |
| Formulario de pago de Stripe (Stripe.js) sin integrar en el portal | Con el checkout embebido el portal lo dice y no cobra nada; solo la demo tiene un formulario simulado |
| Ninguna ruta devuelve el id del PDF de una orden | No hay botón de descarga (`GET /documents/{id}/download` existe, pero el paciente no puede conocer el id) |
| No hay `GET` de factura ni de pago | Al volver de Stripe se dice "estamos confirmando"; la lista de citas pasa a "Confirmada" cuando el webhook confirma; no se retoma una factura tras recargar |
| `/me` solo trae id, roles y permisos | Se muestra el correo |
| Orden sin fechas/médico/nombre de pruebas | Campos opcionales; pruebas como "Prueba N" |
| Reenvío del correo de activación y teléfono en el registro | El enlace vence a las 24 h y no hay forma de pedir otro; el teléfono no se pide |

Si el backend cierra una brecha, actualiza el repositorio `http_*`, quita la limitación de esta tabla y del README.

## Modales y registro

- Iniciar sesión, crear cuenta y reservar cita son **modales** sobre la página de origen (`shared/presentation/layout/modal_route.dart` + `organisms/two_panel_modal.dart`): panel de marca a la izquierda y la tarea a la derecha; en móvil (< 760 px) es una hoja a pantalla completa. Siguen siendo rutas con nombre (`/login`, `/registro`, `/book`), así que el botón atrás funciona. Una pantalla de tarea nueva se hace como modal igual.
- Registro (`POST /api/v1/auth/register`, ya implementado en el backend): solo se envían `email`, `password` (mínimo 12), `first_name` y `last_name`; el servidor rechaza cualquier otro campo con 422 (por eso no hay teléfono ni rol) y fija el rol a paciente. Responde siempre 202, exista o no el correo, así que la app nunca dice "ese correo ya existe". La cuenta queda **inactiva** hasta abrir el enlace del correo (24 h, un solo uso): tras registrarse se muestra "Revisa tu correo", sin iniciar sesión.
- Activación: el enlace llega como `#/verificar?token=…`; la app abre el modal de verificación sobre la página de inicio y llama a `GET /auth/verify-email`. La ruta se lee al arrancar (`AppRouter.initialRoutes`). Hoy el correo del backend enlaza al API (devuelve JSON); para que abra el portal debe apuntar a `FLUTTER_FRONT_URL/#/verificar?token=…`. En modo demo el token válido es `demo`.
- Perfil clínico (`PUT /me/perfil-clinico`, modal `/perfil` y aviso en el portal): altitud de residencia (0 a 8848 m) y si fuma, más los cigarrillos por día si fuma. El backend exige altitud y `fumador` siempre, rechaza un conteo de cigarrillos si no es fumador (se envía `null`) y rechaza campos desconocidos. No hay `GET`: el portal solo recuerda lo declarado mientras la página siga abierta y vuelve a pedirlo tras recargar. Lo documentado en el OpenAPI ("null significa desconocido") no coincide con la validación real.
- Pago (`POST /invoices` + `POST /payments/checkout`, botón "Pagar ahora" en cada cita pendiente): se factura la cita una vez y se abre el checkout con `Idempotency-Key`; la factura y la clave se recuerdan en memoria para que un reintento reutilice el pago pendiente. El puerto devuelve `CheckoutStart`: `Embedded` si la respuesta trae `client_secret` y `publishable_key` (así responde el backend actual), o `RedirectTo` si trae `checkout_url` (solo `https` de `stripe.com`). Con `Embedded` el portal abre `PaymentDialog`, y el formulario lo dibuja `AppDependencies.embeddedCheckout`. **En modo API todavía es `unavailableEmbeddedCheckout`**: dice que el formulario de Stripe no está integrado y no cobra (un mock fingiría un cobro que nunca ocurre); lo que falta es montar Stripe.js con el `client_secret`. **En demo** es `mockEmbeddedCheckout` (rotulado como simulación: se elige una tarjeta de prueba de Stripe, nunca se escribe un número) y pagar confirma la cita como lo haría el webhook. Volver de Stripe (`/pago/exito`, `/pago/cancelado`, rutas con path leídas por `AppRouter.initialRoutes`) **nunca** confirma el pago, solo el webhook firmado; por eso el texto dice "estamos confirmando". Sin claves de Stripe el backend responde 503 y el portal lo dice en español. Reglas puras de pago en `payments/domain`: fuente única (`PaymentSource`), tarjeta guardada vigente preseleccionada y vencida solo informativa, casilla de guardar desmarcada con texto de consentimiento, y errores traducidos con `paymentFailureMessage` (3D Secure antes que el rechazo genérico).
- Tarjetas guardadas (`GET` y `DELETE /me/payment-methods`, pestaña **Pagos**): el servidor las lee de Stripe en cada llamada y no guarda datos de tarjeta; el portal muestra la predeterminada enmascarada (`PaymentCardView`), una vencida como "VENCIDA", y "Quitar tarjeta" pide confirmación. Guardar una tarjeta nueva (`POST /me/payment-methods/setup-intents`) necesita el mismo formulario de Stripe.js: todavía no existe en el portal. En demo la tarjeta es de ejemplo y dura la sesión.
- Citas y órdenes: el portal lista con `GET /appointments` (el servidor ordena por inicio) y `GET /lab/orders?limit=20`; como el listado de órdenes no trae resultados, cada orden se abre con `GET /lab/orders/{id}` y `/results` (una que no se pueda leer no oculta las demás).
- Un login fallido muestra el recordatorio de activar la cuenta: el backend responde igual a "contraseña mal" y "cuenta sin activar".
- Faltan en el backend: reenviar el correo de activación (si el enlace vence la cuenta queda bloqueada) y aceptar el teléfono (la columna existe en `usuarios`).
- Los textos de campos, errores y botones del formulario están en `features/auth/presentation/widgets/`; las reglas (qué es válido) en `features/auth/domain/policies/registration_policy.dart`.

## Errores (paridad con Angular)

`invalidCredentials, unauthenticated, forbidden, notFound, conflict, validation, rateLimited, network, unavailable (502/503/504), notPatient, unknown`.
Los textos en español salen de `describeError` (`shared/presentation/error_message.dart`); no escribas mensajes sueltos en las páginas.

## Mensajes de error

- **Mensajes de error**: nunca muestres `AppError.message` (es interno y está en inglés). Todo texto visible sale de `describeError` en español; del mensaje solo se traducen los campos rechazados por el servidor. Valida los formularios en el cliente, con el error debajo de cada campo, antes de llamar a la API.

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
