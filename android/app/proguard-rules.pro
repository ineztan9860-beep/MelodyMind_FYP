# MelodyMind ProGuard Rules
# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Kotlin
-keep class kotlin.** { *; }

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }
