# Respaldo 24 HS

App de gestión de cámaras WiFi (ONVIF/RTSP), sin publicidad, inspirada en el
flujo de iCSee y V380 Pro pero construida sobre protocolos abiertos.

## Por qué ONVIF/RTSP y no el protocolo original de iCSee/V380

iCSee y V380 Pro usan un protocolo P2P propietario y cifrado para el
emparejamiento "rápido" por QR/UID. Ese protocolo no está documentado
públicamente y, en los modelos más nuevos, ni siquiera la comunidad de
seguridad ha logrado descifrarlo por completo. Reconstruirlo implicaría además
decompilar la app original, lo cual trae problemas legales.

La buena noticia: gran parte de las mismas cámaras (las que trae iCSee
especialmente, y muchos modelos V380/V380 Pro con chips Anyka o GM) **también**
exponen video por RTSP y control por ONVIF directo en la red local — el mismo
estándar que usan Hikvision, Dahua, Blue Iris, Agent DVR, etc. Esta app se
construye sobre eso.

**Limitación real:** si tu cámara puntual es de las que *solo* hablan el
protocolo P2P cerrado (sin RTSP/ONVIF abierto en LAN — ver sección
"Cómo saber si tu cámara sirve" más abajo), esa cámara en particular no se va
a poder agregar sin construir además un servidor de relay P2P propio, que es
un proyecto bastante más grande (ver Hoja de ruta).

## Cómo saber si tu cámara sirve

1. Conectá tu celular/PC a la misma red WiFi que la cámara.
2. Buscá la IP de la cámara (en el router, o en la propia app iCSee/V380 Pro,
   sección de información del dispositivo).
3. Probá si responde:
   - Puerto RTSP: `554`
   - Puerto ONVIF: `8899` (o `80` en algunas marcas)
4. Si tenés `nmap` a mano: `nmap -p 554,8899,80 <ip-de-la-camara>`
5. Alternativa sin instalar nada: usá la app gratuita **Agent DVR** u
   **ONVIF Device Manager** en PC, que auto-descubren cámaras ONVIF en la red.

Si el puerto 554 y/o 8899 aparecen abiertos, tu cámara es candidata perfecta
para esta app.

## Arquitectura del proyecto

```
lib/
  models/camera_device.dart        Modelo de datos de una cámara guardada
  services/camera_storage_service.dart   Persistencia local (SharedPreferences)
  services/onvif_camera_service.dart     Descubrimiento LAN + ONVIF + PTZ
  providers/camera_provider.dart         Estado reactivo (Provider/ChangeNotifier)
  screens/home_screen.dart               Grilla de cámaras (estilo iCSee/V380)
  screens/add_camera_screen.dart         Buscar en LAN + alta manual
  screens/live_view_screen.dart          Video en vivo (RTSP) + PTZ + snapshot
  screens/camera_settings_screen.dart    Editar/eliminar cámara
  widgets/                                Componentes reutilizables
  theme/app_theme.dart                    Tema oscuro sin espacio para banners
```

Todo el listado de cámaras se guarda **solo en el dispositivo** — no hay
cuenta, login ni servidor propio. Esa es la principal diferencia de fondo
frente a iCSee/V380 Pro además de la ausencia de publicidad.

## Opción rápida: dejar que GitHub compile el APK por vos (sin instalar nada)

Este repo incluye `.github/workflows/build-apk.yml`, que compila el APK
automáticamente en los servidores de GitHub cada vez que subís cambios.
No necesitás instalar Flutter, Android Studio, ni nada localmente.

1. Creá una cuenta gratuita en https://github.com si no tenés una.
2. Creá un repositorio nuevo (puede ser público o privado), por ejemplo
   `respaldo24hs`.
3. Subí el contenido de esta carpeta al repositorio. La forma más simple sin
   usar la línea de comandos: en la página del repo, botón
   **Add file → Upload files**, y arrastrá ahí toda la carpeta descomprimida
   (incluida la carpeta oculta `.github`, asegurate de que se suba también).
4. Andá a la pestaña **Actions** del repositorio. Debería aparecer una
   ejecución en curso ("Build Android APK") o dale a **Run workflow** si no
   arrancó sola.
5. Esperá a que termine (2-5 minutos, ícono verde ✅).
6. Entrá a esa ejecución terminada y bajá hasta **Artifacts** → descargá
   `respaldo24hs-apk` (te baja un .zip que contiene el `.apk` adentro).
7. Pasá ese `.apk` a tu teléfono (por USB, Drive, WhatsApp a vos mismo, lo que
   uses) y abrilo desde el teléfono para instalarlo. La primera vez, Android
   va a pedirte permitir "instalar apps de un origen desconocido" — aceptalo
   solo para ese archivo.

Si el workflow falla (ícono rojo ❌), abrí esa ejecución y fijate en qué paso
truncó — pegame el log de ese paso y lo arreglamos.

## Cómo compilar en tu propia PC (alternativa local)

Este código se generó en un entorno sin el SDK de Flutter instalado y sin
acceso a pub.dev, así que **no se pudo compilar ni probar contra una cámara
real**. Los pasos para dejarlo andando en tu máquina:

```bash
# 1. Si no tenés el andamiaje nativo (android/, ios/) generado por Flutter:
flutter create --project-name respaldo24hs --org com.tuempresa .
# (esto no pisa el contenido de lib/, pubspec.yaml ni este README
#  si ya existen, pero hacé un respaldo por las dudas)

# 2. Instalar dependencias
flutter pub get

# 3. Conectar un dispositivo/emulador y correr
flutter run
```

### Permisos que vas a necesitar agregar

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

**iOS** (`ios/Runner/Info.plist`), para permitir tráfico RTSP/HTTP sin TLS y
descubrimiento en la red local:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
<key>NSLocalNetworkUsageDescription</key>
<string>Respaldo 24 HS necesita acceder a tu red local para encontrar y
conectarse a tus cámaras.</string>
```

### Si el compilador marca errores en `onvif_camera_service.dart`

Las APIs de `easy_onvif` cambiaron de nombre entre versiones (está documentado
en su propio changelog). Ese archivo tiene comentarios marcando exactamente
qué revisar. Si te tildás con algún error de compilación puntual, pegame el
mensaje de error y lo ajustamos juntos.

## Hoja de ruta (no incluido en esta primera versión)

- **Alertas de movimiento**: si la cámara soporta eventos ONVIF (`PullPoint`),
  se puede suscribir y disparar notificaciones locales.
- **Reproducción de grabaciones**: si la cámara tiene tarjeta SD, algunas
  exponen un servicio ONVIF `Replay`/`Search`, o un endpoint HTTP propio del
  fabricante (varía mucho por marca).
- **Acceso remoto (fuera de tu WiFi)**: a diferencia del P2P cerrado de
  iCSee/V380, acá las opciones honestas son (a) una VPN a tu propia red
  (WireGuard/Tailscale, lo más simple y seguro), (b) port-forward + DNS
  dinámico si tu ISP lo permite, o (c) un servidor relay propio (bastante más
  trabajo, similar en espíritu al servidor P2P de esas apps pero bajo tu
  control). No se incluye una reimplementación del protocolo P2P original.
- **Multi-cámara con grabación continua**: pensado como un servicio en
  background o companion en PC (tipo NVR casero), no solo la app móvil.

## Sobre el nombre de paquete de iCSee/V380

Este proyecto no reutiliza ni un byte de código de iCSee ni de V380 Pro. Toma
como referencia únicamente el *flujo de uso* (grilla de dispositivos, alta de
cámara, vista en vivo, ajustes) — el mismo tipo de flujo que usan decenas de
apps de cámaras IP genéricas.
