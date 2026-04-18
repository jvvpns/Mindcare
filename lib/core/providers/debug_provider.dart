import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the debug mode state for the application.
/// When enabled, advanced developer tools like the Reaction Log are visible.
final debugModeProvider = StateProvider<bool>((ref) => false);
