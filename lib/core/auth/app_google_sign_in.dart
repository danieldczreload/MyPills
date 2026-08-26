import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_pills/core/config/env_config.dart';

/// Single app-wide GoogleSignIn instance.
///
/// google_sign_in keeps one instance per process and the first construction
/// wins, so every feature (login and calendar connect) must reuse this object
/// instead of building its own with different parameters.
final GoogleSignIn appGoogleSignIn = GoogleSignIn(
  scopes: const ['email', 'profile'],
  serverClientId: EnvConfig.effectiveGoogleServerClientId.isNotEmpty
      ? EnvConfig.effectiveGoogleServerClientId
      : null,
  // Ensures every sign-in mints a fresh serverAuthCode instead of returning
  // one bound to an older grant (e.g. before the calendar scope was added).
  forceCodeForRefreshToken: true,
);
