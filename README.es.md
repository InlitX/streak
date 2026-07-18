<div align="center">

<img src="assets/icon.svg" width="120" alt="Logo de Streak" />

# Streak

### Un rastreador de hábitos minimalista, privado y sin anuncios hecho con Flutter

Registra un hábito con un solo toque, mantén tu constancia y mira crecer tus rachas.

<br/>

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white" />
  <img alt="Android" src="https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white" />
  <img alt="Licencia MIT" src="https://img.shields.io/badge/License-MIT-7C3AED?style=flat&logo=opensourceinitiative&logoColor=white" />
  <img alt="Sin anuncios, sin rastreo" src="https://img.shields.io/badge/No%20ads%20%C2%B7%20No%20tracking-22C55E?style=flat&logo=shield&logoColor=white" />
</p>

<br/>

<a href="https://f-droid.org/packages/com.streak.app/"><img alt="Disponible en F-Droid" src="assets/badges/get-it-on-fdroid.png" height="60" /></a>
&nbsp;
<a href="https://apt.izzysoft.de/fdroid/index/apk/com.streak.app?repo=main"><img alt="Disponible en IzzyOnDroid" src="assets/badges/get-it-on-izzyondroid.png" height="60" /></a>
&nbsp;
<a href="https://github.com/InlitX/streak/releases"><img alt="Disponible en GitHub" src="assets/badges/get-it-on-github.png" height="60" /></a>

<br/>
<br/>

[English](README.md) · **Español** · [中文](README.zh-CN.md)

</div>

---

> [!TIP]
> **Tuya, por completo.** Sin cuentas, sin suscripciones, sin anuncios, sin rastreo.
> Cada hábito y ajuste se queda en tu dispositivo, y todo el código es abierto.

## Resumen

Streak es un rastreador de hábitos que te respeta. Crea todos los hábitos que
quieras, regístralos con un toque y sigue tu progreso a través de una cuadrícula
de actividad al estilo de GitHub, contadores de racha y un panel de estadísticas.
Es rápido, funciona sin conexión y está pensado para transmitir calma en lugar de
exigir.

---

## Capturas

<p align="center">
  <img src="docs/screenshots/01-today.png" alt="Hoy" width="150" />
  <img src="docs/screenshots/02-stats.png" alt="Estadísticas" width="150" />
  <img src="docs/screenshots/03-insights.png" alt="Análisis" width="150" />
  <img src="docs/screenshots/04-customize.png" alt="Personaliza" width="150" />
  <img src="docs/screenshots/05-free.png" alt="Libre y privada" width="150" />
</p>

<div align="center"><sub><b>Hoy</b> · <b>Estadísticas</b> · <b>Análisis</b> · <b>Personaliza</b> · <b>Libre y privada</b></sub></div>

---

## Descarga

La forma más fácil es [**F-Droid**](https://f-droid.org/packages/com.streak.app/), que
instala Streak y lo mantiene actualizado automáticamente.

¿Prefieres el APK directo? Consíguelo en la página de [**Releases**](https://github.com/InlitX/streak/releases).
Las compilaciones están divididas por arquitectura de CPU para que cada descarga
sea pequeña: elige la que corresponda a tu teléfono (la mayoría de los
dispositivos modernos son **arm64-v8a**):

| APK | Para |
|-----|------|
| `Streak-arm64-v8a.apk` | Teléfonos modernos de 64 bits (recomendado) |
| `Streak-armeabi-v7a.apk` | Dispositivos antiguos de 32 bits |
| `Streak-x86_64.apk` | Emuladores / tablets x86 |

> [!NOTE]
> Streak no está en la Play Store. Como el APK no proviene de una tienda, puede
> que Android te pida permitir instalaciones desde tu navegador o gestor de
> archivos la primera vez.

---

## Características

<table>
<tr>
<td width="50%" valign="top">

**Seguimiento**
- Registro con un toque desde la pantalla de inicio
- Metas diarias, semanales y mensuales
- Contadores de racha actual y mejor racha
- "Fuerza" del hábito basada en la constancia reciente

</td>
<td width="50%" valign="top">

**Visualización**
- Cuadrícula de actividad al estilo de GitHub (semana / mes / año)
- Panel de estadísticas con tendencias y totales
- Tarjeta de progreso para compartir como una imagen cuidada

</td>
</tr>
<tr>
<td width="50%" valign="top">

**Personalización**
- Pack de iconos minimalista y soporte de emojis
- Color de acento personalizado con un selector de color completo
- Temas claro / oscuro y fondos seleccionables
- Categorías, reordenación, nombre y foto de perfil

</td>
<td width="50%" valign="top">

**Datos y plataforma**
- Recordatorios por hábito en los días que elijas
- Copia de seguridad y restauración como archivo JSON portable
- Tres widgets para la pantalla de inicio
- Inglés y español, totalmente sin conexión

</td>
</tr>
</table>

---

## Tecnologías

| Área | Elección |
|------|----------|
| Framework | Flutter (Dart) |
| Gestión de estado | provider |
| Almacenamiento local | hive_ce |
| Gráficos | fl_chart |
| Notificaciones | flutter_local_notifications + timezone |
| Widgets de inicio | home_widget + Jetpack Glance (Kotlin) |
| Iconos | Lucide |

---

## Estructura del proyecto

<details open>
<summary><b>Distribución de carpetas</b></summary>

```
lib/
├── main.dart                 Punto de entrada y callback del widget de inicio
├── app/                      Estructura de la app, navegación y temas
│   └── theme/                Paleta, tokens de diseño, temas claro/oscuro
├── core/                     Bloques transversales
│   ├── database/             Persistencia local (Hive)
│   ├── extensions/           Utilidades de fecha
│   ├── i18n/                 Cadenas localizadas
│   ├── icons/                Catálogos de iconos y emojis
│   ├── routing/              Navegación y transiciones de página
│   ├── utils/                Snackbars y utilidades
│   └── widgets/              Componentes de UI compartidos
├── features/                 Módulos organizados por funcionalidad
│   ├── habits/               data · state · pages · widgets
│   ├── statistics/           Panel de estadísticas
│   ├── settings/             Preferencias y Acerca de
│   └── onboarding/           Experiencia de primer uso
└── services/                 Notificaciones, widgets de inicio, copias

android/                      Proyecto Android y layouts de los widgets
assets/                       Icono de la app e imágenes incluidas
fonts/                        Figtree y Playfair Display
docs/screenshots/             Capturas usadas en este README
tool/                         Scripts de generación de iconos (solo desarrollo)
```

</details>

---

## Primeros pasos

### Requisitos

- SDK de Flutter (canal stable)
- Android Studio o el SDK de Android, con un dispositivo o emulador

### Ejecutar

```bash
git clone https://github.com/InlitX/streak.git
cd streak
flutter pub get
flutter run
```

### Compilar los APK de release

```bash
# un APK por arquitectura (arm64-v8a, armeabi-v7a, x86_64)
flutter build apk --release --split-per-abi
```

Al publicar una etiqueta `v*` se ejecuta el flujo de GitHub Actions, que compila
estos APK divididos más un archivo con el código fuente y los adjunta a una nueva
Release de GitHub.

> [!TIP]
> Para firmar una compilación de release, crea `android/key.properties` con los
> datos de tu keystore. Ese archivo y cualquier keystore están ignorados por git
> a propósito; sin ellos, las compilaciones de release usan la clave de firma de
> depuración.

---

## Notas de arquitectura

- **Organización por funcionalidad.** Cada funcionalidad posee sus propios
  modelos de datos, controladores de estado, páginas y widgets, manteniendo los
  límites claros.
- **Una única fuente de verdad.** Hábitos, categorías y ajustes se persisten en
  Hive y se exponen a través de controladores `ChangeNotifier`.
- **Almacenamiento resiliente.** Los registros corruptos o con esquema no
  coincidente se omiten en lugar de bloquear el arranque, y el trabajo no
  crítico de inicio (notificaciones, widgets) está aislado para que nunca pueda
  impedir que la app se abra.
- **Navegación consistente.** Cada navegación pasa por un único navigator con
  transiciones de página opacas, de modo que las pantallas nunca se transparentan
  durante las animaciones.

---

## Privacidad

> [!IMPORTANT]
> Streak **no tiene analíticas, ni SDK de publicidad, ni backend de red**.
> La app nunca envía tus datos a ningún sitio: se quedan en tu dispositivo. Las
> únicas acciones salientes son los enlaces que tú decides abrir.

---

## Apoyo

<div align="center">

Si Streak te ayuda a mantener la constancia, una estrella o un café significan mucho:

<a href="https://github.com/InlitX/streak"><img src="https://img.shields.io/badge/Star%20on%20GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="Estrella en GitHub" height="38" /></a>
&nbsp;&nbsp;
<a href="https://ko-fi.com/inlitx"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="Apóyame en Ko-fi" height="38" /></a>

</div>

---

## Contribuir

Las incidencias y pull requests son bienvenidas. Para cambios grandes, abre
primero una incidencia para comentar la dirección.

---

## Licencia

Publicado bajo la [Licencia MIT](LICENSE).
