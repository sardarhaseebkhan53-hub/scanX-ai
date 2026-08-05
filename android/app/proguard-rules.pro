# ProGuard / R8 rules for ScanX AI (Android API 36 / NDK 30)

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# ML Kit OCR & Vision protection
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**

# CameraX & ImagePicker protection
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# AdMob protection
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Google Play Billing protection
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Hive / Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**
