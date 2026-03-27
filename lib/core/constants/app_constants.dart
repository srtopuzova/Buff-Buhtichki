import 'package:medshelf/config/secrets.dart';

class AppConstants {
  // Claude API
  static const String claudeApiKey = Secrets.claudeApiKey;
  static const String claudeModelFast = 'claude-haiku-4-5-20251001';
  static const String claudeModelSmart = 'claude-sonnet-4-6';
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';

  // Google Places API (New)
  static const String googleMapsApiKey = Secrets.googleMapsApiKey;
  static const String googlePlacesUrl =
      'https://places.googleapis.com/v1/places:searchNearby';

  // App
  static const String appName = 'MedShelf';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String medicationsCollection = 'medications';
  static const String prescriptionsCollection = 'prescriptions';

  // Notification IDs
  static const int expiryNotificationBase = 1000;
  static const int doseNotificationBase = 2000;

  // Expiry thresholds (days)
  static const List<int> expiryWarningDays = [30, 7, 3, 0];

  // Storage paths
  static const String medicationImagesPath = 'medication_images';
  static const String prescriptionImagesPath = 'prescription_images';

  // Shared prefs keys
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String onboardingCompletedKey = 'onboarding_completed';
}
