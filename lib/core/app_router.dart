import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/verify_code_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/places/screens/full_map_screen.dart';
import '../features/places/screens/my_places_screen.dart';
import '../features/places/screens/publish_place_screen.dart';
import '../features/reservations/screens/reservations_screen.dart';
import '../features/splash/splash_screen.dart';

bool isValidRedirect(String? redirect) {
  if (redirect == null || redirect.isEmpty) return false;
  final uri = Uri.tryParse(redirect);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
  if (!redirect.startsWith('/') || redirect.startsWith('//')) return false;

  const blockedAuthRoutes = {
    '/',
    '/welcome',
    '/login',
    '/signup',
  };
  return !blockedAuthRoutes.contains(uri.path);
}

String authRouteWithRedirect(String route, String? redirect) {
  if (!isValidRedirect(redirect)) return route;
  return Uri(path: route, queryParameters: {'redirect': redirect}).toString();
}

String authSuccessDestination(String? redirect) {
  if (!isValidRedirect(redirect)) return '/loading-dashboard';
  final uri = Uri.parse(redirect!);
  return uri.path == '/dashboard' ? '/loading-dashboard' : redirect;
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', redirect: (context, state) => '/dashboard'),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final rawRedirect = state.uri.queryParameters['redirect'];
          final redirect = rawRedirect != null
              ? Uri.decodeComponent(rawRedirect)
              : null;
          return LoginScreen(redirect: redirect);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final extra = state.extra;
          final redirect = extra is Map<String, dynamic>
              ? extra['redirect'] as String?
              : null;
          return SignupScreen(redirect: redirect);
        },
      ),
      GoRoute(
        path: '/verify-code',
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map<String, dynamic>
              ? extra
              : const <String, dynamic>{};
          return VerifyCodeScreen(
            email: (map['email'] as String?) ?? '',
            redirect: map['redirect'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/loading-dashboard',
        builder: (context, state) => const DashboardLoaderScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) {
          final extra = state.extra;
          return FullMapScreen(
            initialListing: extra is FullMapRouteExtra
                ? extra.initialListing
                : null,
            openedFromPlace: extra is FullMapRouteExtra
                ? extra.openedFromPlace
                : false,
          );
        },
      ),
      GoRoute(
        path: '/reservations',
        builder: (context, state) => const ReservationsScreen(),
      ),
      GoRoute(
        path: '/my-places',
        builder: (context, state) => const MyPlacesScreen(),
      ),
      GoRoute(
        path: '/publish-place',
        builder: (context, state) => const PublishPlaceScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocumentType.terms),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocumentType.privacy),
      ),
    ],
  );
}
