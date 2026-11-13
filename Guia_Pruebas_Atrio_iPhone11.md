# 📱 **Guía Diaria: Probar ATRIO en iPhone 11** 
Ejecución nativa desde Windows con **xcross** y automatización con Agente IA (Flutter Driver) 
**Proyecto: Dispositivo:** iPhone 11 **Apple ID: Bundle ID:** XCRC:\APPS\ATRIO ("Leningrado") leningrado777@gmail.com 8NY6488LNH.com.example.atrio 

## **Etapa 1: Conectar el iPhone (30 segundos)** 
1. Conecta tu **iPhone 11** por cable USB a tu PC Windows. 
2. **Desbloquéalo** y mantenlo con la pantalla encendida. 
3. Si aparece en el iPhone el aviso _"¿Confiar en este ordenador?"_ , toca **Confiar** e ingresa tu código de desbloqueo. 
## **Etapa 2: Iniciar el Túnel iOS (Terminal como Administrador)** 
1. Haz clic derecho en el botón Inicio de Windows y selecciona **Terminal (Administrador)** o **PowerShell (Administrador)** . 
2. Ejecuta el siguiente comando: 
xcross tunnel 

3. **Importante:** No cierres esta ventana. Déjala minimizada mientras duren tus pruebas. 
## **Etapa 3: Lanzar Atrio en el iPhone (Terminal Normal)** 
Abre una terminal normal de PowerShell y sitúate en la carpeta del proyecto: 
cd C:\APPS\ATRIO 
Elige una de las 3 modalidades según lo que desees hacer hoy: 

- ✅ **Opción A — Modo con Agente IA + Teclado físico activo (Recomendado)** 
Permite usar la app manualmente en tu iPhone (con el teclado nativo de iOS funcionando) y al mismo tiempo permite que el Agente IA inspeccione o conduzca la pantalla: 
xcross flutter run --target test_driver/main_driver.dart --usb 


- 🔹 **Opción B — Modo Debug Estándar (Solo uso manual)** 
Úsalo cuando quieras probar y hacer Hot Reload sin habilitar Flutter Driver: 
xcross flutter run --usb 

### 🚀 **Opción C — Modo Release Independiente (Para usar sin cable ni PC)** 
En modo Debug iOS exige estar conectado a la PC. Si quieres desconectar el cable y abrir Atrio desde el icono del iPhone en cualquier lugar: 

xcross flutter run --release --usb 

## **Etapa 4: Conectar al Agente IA (Opcional)** 

Si lanzaste la **Opción A** y deseas que el asistente conduzca las pruebas o inspeccione errores en tiempo real: 
1. Espera a que la app abra en tu iPhone y busca al final de la terminal la línea: 
›  vm-service: ws:--127.0.0.1:XXXXX/ws 
2. Copia esa URL y pégala en el chat del Agente IA indicando qué flujo deseas probar. 
## ⌨ **Atajos Interactivos en la Terminal** 
**`r R q` Hot Reload Hot Restart Salir (Quit)** Aplica cambios de código en 1 Reinicia la aplicación completa Detiene la ejecución y cierra la seg sin perder el estado desde el inicio. sesión activa. actual. 
## 🛠 **Solución Rápida de Problemas Frecuentes** 
|**Síntoma o Mensaje**|**Causa**|**Solución paso a paso**|
|---|---|---|
|Your session has<br>expired. Please log<br>in (HTTP 401)|La sesión del Apple ID en<br>xcross caduca cada cierto<br>días.|Ejecuta en terminal:<br>xcross auth--apple-id<br>leningrado777@gmail.com<br>Ingresa tu contraseña y el código SMS de 6<br>dígitos.|
|GrandSlam.<br>failed (HTTP 403)|Nueva versión de<br>xcross<br>disponible o estado Anisette<br>vencido.|Ejecuta en orden:<br>1.<br>xcross update<br>2.<br>xcross auth clean<br>3.<br>xcross auth--apple-id<br>leningrado777@gmail.com|
|**Síntoma o Mensaje**|**Causa**|**Solución paso a paso**|
|---|---|---|
|Aviso**"Desarrollador no**<br>**confiable"**en el iPhone|El certificado gratuito de Apple se<br>renueva cada**7 días**.|En el iPhone ve a:_Configuración → General →_<br>_Administración de dispositivos y VPN_→ Toca<br>leningrado777@gmail.com→**Confiar**.|
|Pantalla negra:_"In iOS 14+,_|Tocaste el icono de Atrio en el|Lánzala desde la PC con<br>xcross flutter|
|_debug mode Flutter apps_<br>_can only be launched from_<br>_Flutter tooling..."_|iPhone teniendo instalada una<br>compilación_Debug_.|run.--o instálala con el flag<br>--release<br>para abrirla sin PC.|
|No aparece el teclado en el|Se ejecutó sin|Ya está corregido en|
|iPhone al tocar un campo|enableTextEntryEmulation:|test_driver/main_driver.dart .|
|de texto|false .|Presiona<br>R(mayúscula) en la terminal para<br>reiniciar.|
|Se queda en<br>Finding|El túnel se cerró o el iPhone está|Desbloquea el iPhone, verifica el cable USB y|
|devices…o no detecta|bloqueado.|confirma que la ventana de Administrador con|
|el iPhone||xcross tunnel siga abierta.|