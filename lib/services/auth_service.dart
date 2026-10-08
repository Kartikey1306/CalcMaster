import 'package:shared_preferences/shared_preferences.dart';

/// Local, offline session + guest-mode persistence.
///
/// CalcMaster does NOT require an account — it opens straight to the calculator
/// as a guest. This service persists the guest choice across launches via
/// [SharedPreferences], so the app never re-prompts for sign-in. Accounts
/// themselves are Supabase sessions (see [AuthProvider]).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Human-friendly name shown for the offline demo session.

  static const String _kEmailKey = 'local_auth_email';
  static const String _kGuestKey = 'guest_mode';

  String? _email;
  String? get email => _email;

  bool _guest = false;

  /// True when the user has chosen to continue as a guest.
  bool get isGuest => _guest;

  /// True when an offline demo session is active.
  bool get isAuthenticated => _email != null;

  /// Restores the persisted guest flag. Safe to call once at startup.
  ///
  /// A leftover offline test-account session is discarded rather than
  /// restored. Nothing writes one any more — the device no longer accepts
  /// test credentials locally — but an install that saved one before would
  /// otherwise open signed in as "Test User" and block a real Supabase session
  /// from taking over.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_kEmailKey)) await prefs.remove(_kEmailKey);
    _email = null;
    _guest = prefs.getBool(_kGuestKey) ?? false;
  }

  /// Persists the guest choice so relaunches never re-prompt for sign-in.
  Future<void> setGuest() async {
    _guest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGuestKey, true);
  }

  /// Clears the persisted offline demo session (used on sign-out).
  Future<void> signOut() async {
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmailKey);
  }
}
