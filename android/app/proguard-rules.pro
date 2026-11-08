# Reglas de protección R8 / ProGuard para Google Sign-In y Google Play Services Auth
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class io.flutter.plugins.googlesignin.** { *; }
-dontwarn com.google.android.gms.**

# Reglas de protección para reproducción de audio en segundo plano (audio_service / just_audio)
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }


