# Regla del Proyecto: Requisitos Mínimos de Sistema Operativo

**REGLA ESTRICTA DE COMPILACIÓN Y DESPLIEGUE:**
- **Android:** Versión mínima **Android 10 (API level 29)** configurada en `android/app/build.gradle.kts` mediante `minSdk = 29`. No se permite compilar ni soportar versiones inferiores (Android 9 o anterior).
- **iOS:** Versión mínima **iOS 18.0 o superior** configurada en `ios/Runner.xcodeproj/project.pbxproj` (`IPHONEOS_DEPLOYMENT_TARGET = 18.0`) en todas las configuraciones (`Debug`, `Release`, `Profile`), asegurando compatibilidad exclusiva con iPhone 11 en adelante.
