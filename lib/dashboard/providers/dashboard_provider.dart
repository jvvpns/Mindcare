import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

/// Provides a randomly selected daily quote that persists until the app restarts,
/// or can be manually refreshed if needed.
final dailyQuoteProvider = StateProvider<String>((ref) {
  final random = Random();
  final quotes = AppConstants.dailyQuotes;
  return quotes[random.nextInt(quotes.length)];
});
