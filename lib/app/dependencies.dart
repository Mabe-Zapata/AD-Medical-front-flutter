import 'package:http/http.dart' as http;
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/core/navigation/open_page.dart';
import 'package:medicalbooking_portal/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/data/repositories/http_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/data/session/memory_session_store.dart' as memory;
import 'package:medicalbooking_portal/features/auth/data/session/session_store_factory.dart';
import 'package:medicalbooking_portal/features/auth/domain/repositories/auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/register_patient.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/restore_session.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_in.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_out.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/verify_email.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
import 'package:medicalbooking_portal/features/booking/data/repositories/demo_appointment_repository.dart';
import 'package:medicalbooking_portal/features/booking/data/repositories/http_appointment_repository.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/cancel_appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_day_slots.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_my_appointments.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/reserve_appointment.dart';
import 'package:medicalbooking_portal/features/catalog/data/repositories/demo_catalog_repository.dart';
import 'package:medicalbooking_portal/features/catalog/data/repositories/static_catalog_repository.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/domain/usecases/get_catalog.dart';
import 'package:medicalbooking_portal/features/lab_results/data/repositories/demo_lab_results_repository.dart';
import 'package:medicalbooking_portal/features/lab_results/data/repositories/http_lab_results_repository.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';
import 'package:medicalbooking_portal/features/profile/data/repositories/demo_clinical_profile_repository.dart';
import 'package:medicalbooking_portal/features/profile/data/repositories/http_clinical_profile_repository.dart';
import 'package:medicalbooking_portal/features/profile/domain/usecases/save_clinical_profile.dart';
import 'package:medicalbooking_portal/features/profile/presentation/controllers/clinical_profile_controller.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/demo_payment_repository.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/http_payment_repository.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/demo_saved_card_repository.dart';
import 'package:medicalbooking_portal/features/payments/data/repositories/http_saved_card_repository.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/payment_source.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/get_saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/remove_saved_card.dart';
import 'package:medicalbooking_portal/features/payments/domain/usecases/start_checkout.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/mock_embedded_checkout.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

/// Composition root: the only place that knows the concrete repositories.
///
/// Two modes share every use case, controller and page; only the adapters differ:
/// * [AppDependencies.demo]: in-memory data, nothing leaves the browser.
/// * [AppDependencies.api]: the real REST API for login, availability, reservations and results.
///   The public catalog stays static because the backend has no endpoint for it yet.
class AppDependencies {
  AppDependencies._({
    required this.isDemo,
    required this.session,
    required this.verifyEmail,
    required this.clinicalProfiles,
    required this.getCatalog,
    required this.getDaySlots,
    required this.reserveAppointment,
    required this.getMyAppointments,
    required this.cancelAppointment,
    required this.getMyLabOrders,
    required this.startCheckout,
    required this.getSavedCard,
    required this.openPage,
    required this.embeddedCheckout,
    required this.removeSavedCard,
    this.payWithCard,
    this.demoCredentials,
  });

  factory AppDependencies.demo({Duration latency = const Duration(milliseconds: 600)}) {
    final db = DemoDatabase(latency: latency);
    final store = memory.MemorySessionStore();
    final auth = DemoAuthRepository(db);
    final appointments = DemoAppointmentRepository(db);
    final labs = DemoLabResultsRepository(db);
    final payments = DemoPaymentRepository(db);
    final savedCards = DemoSavedCardRepository(db);
    return AppDependencies._(
      isDemo: true,
      session: _session(auth, store),
      verifyEmail: VerifyEmail(auth),
      clinicalProfiles: ClinicalProfileController(save: SaveClinicalProfile(DemoClinicalProfileRepository(db))),
      getCatalog: GetCatalog(DemoCatalogRepository(db)),
      getDaySlots: GetDaySlots(appointments),
      reserveAppointment: ReserveAppointment(appointments),
      getMyAppointments: GetMyAppointments(appointments),
      cancelAppointment: CancelAppointment(appointments),
      getMyLabOrders: GetMyLabOrders(labs),
      startCheckout: StartCheckout(payments),
      getSavedCard: GetSavedCard(savedCards),
      removeSavedCard: RemoveSavedCard(savedCards),
      openPage: (_) {},
      embeddedCheckout: mockEmbeddedCheckout,
      payWithCard: payments.payWithCard,
      demoCredentials: (email: DemoDatabase.demoEmail, password: DemoDatabase.demoPassword),
    );
  }

  /// [apiBaseUrl] is absolute or origin-relative (`/api/v1`). [services] are the bookable services
  /// of the target environment; without them the demo services are used and a real reservation
  /// will be refused because their ids are not UUIDs of that backend.
  factory AppDependencies.api({
    required String apiBaseUrl,
    List<MedicalService>? services,
    http.Client? client,
    SessionStore? store,
    DateTime Function() now = DateTime.now,
    void Function(Uri)? openPage,
    EmbeddedCheckoutBuilder? embeddedCheckout,
  }) {
    late final SessionController session;
    final api = ApiClient(
      client: client ?? http.Client(),
      baseUrl: apiBaseUrl,
      token: () => session.token,
      onUnauthorized: () => session.expire(),
    );
    final auth = HttpAuthRepository(api);
    session = _session(auth, store ?? createSessionStore(), now: now);
    final appointments = HttpAppointmentRepository(api, now: now);
    final labs = HttpLabResultsRepository(api);
    final savedCards = HttpSavedCardRepository(api);
    final content = DemoDatabase(latency: Duration.zero);
    return AppDependencies._(
      isDemo: false,
      session: session,
      verifyEmail: VerifyEmail(auth),
      clinicalProfiles: ClinicalProfileController(save: SaveClinicalProfile(HttpClinicalProfileRepository(api))),
      getCatalog: GetCatalog(
        StaticCatalogRepository(
          Catalog(
            branches: content.branches,
            services: services ?? content.services,
            testTypes: content.testTypes,
          ),
        ),
      ),
      getDaySlots: GetDaySlots(appointments),
      reserveAppointment: ReserveAppointment(appointments),
      getMyAppointments: GetMyAppointments(appointments),
      cancelAppointment: CancelAppointment(appointments),
      getMyLabOrders: GetMyLabOrders(labs),
      startCheckout: StartCheckout(HttpPaymentRepository(api)),
      getSavedCard: GetSavedCard(savedCards),
      removeSavedCard: RemoveSavedCard(savedCards),
      openPage: openPage ?? openExternalPage,
      // The real form (Stripe.js) goes here. Until then the portal says so instead of pretending to charge.
      embeddedCheckout: embeddedCheckout ?? unavailableEmbeddedCheckout,
    );
  }

  static SessionController _session(
    AuthRepository auth,
    SessionStore store, {
    DateTime Function() now = DateTime.now,
  }) => SessionController(
    signIn: SignIn(auth, store, now: now),
    signOut: SignOut(store),
    register: RegisterPatient(auth),
    restore: RestoreSession(store, now: now),
    now: now,
  );

  /// True when running on the in-memory demo, so screens can say so.
  final bool isDemo;

  /// Only set by the demo build, to prefill and explain the login form.
  final ({String email, String password})? demoCredentials;

  final SessionController session;
  final VerifyEmail verifyEmail;
  final ClinicalProfileController clinicalProfiles;
  final GetCatalog getCatalog;
  final GetDaySlots getDaySlots;
  final ReserveAppointment reserveAppointment;
  final GetMyAppointments getMyAppointments;
  final CancelAppointment cancelAppointment;
  final GetMyLabOrders getMyLabOrders;
  final StartCheckout startCheckout;
  final GetSavedCard getSavedCard;

  /// Sends the browser to another page (the hosted payment page); a test replaces it.
  final void Function(Uri) openPage;

  /// Draws the embedded payment form.
  final EmbeddedCheckoutBuilder embeddedCheckout;

  final RemoveSavedCard removeSavedCard;

  /// Demo only: plays the backend's part when the simulated card form is submitted. The real form will send
  /// the payment itself.
  final Future<void> Function({
    required String patientId,
    required String appointmentId,
    required PaymentSource source,
  })?
  payWithCard;

  /// Stops what the dependencies keep running (the session expiry timer).
  void dispose() {
    session.dispose();
    clinicalProfiles.dispose();
  }
}
