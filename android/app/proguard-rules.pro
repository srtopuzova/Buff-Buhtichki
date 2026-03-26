# Flutter local notifications
-keep class com.dexterous.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Keep R class
-keepclassmembers class **.R$* {
    public static <fields>;
}
