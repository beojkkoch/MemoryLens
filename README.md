# MemoryLens
Proyecto Apps Moviles

Aplicación móvil que funciona como una memoria inteligente para el dispositivo. Su objetivo es analizar la galería de fotos del usuario para extraer, verificar y organizar información clave contenida en las imágenes, a partir de peticiones o consultas puntuales en lenguaje natural.

## Cómo correrlo

El proyecto de Flutter está en la raíz del repositorio:

```bash
flutter pub get
flutter run
```

La `Project URL` y la `publishable key` de Supabase están en `lib/main.dart`.

## Cómo navegar la app

La app tiene **un solo tipo de usuario**: la persona dueña de la galería. 

```text
Bienvenida ──► Registro (paso 1 → paso 2) ──► Confirma tu correo ──► Iniciar sesión ──► Recuerdos ──► Analizando
     │                                                                    ▲                │
     └──────────────── Continuar con correo electrónico ─────────────────┘                ▼
     ▲                                                                                 Mi perfil
     └─────────────────────────────── Cerrar sesión ◄────────────────────────────────────┘
```

### 1. Bienvenida

Pantalla inicial con el logo de Memory Lens AI.

- **Regístrate**: abre el registro (cuenta nueva).
- **Continuar con correo electrónico**: abre el inicio de sesión (cuenta existente).

### 2. Registro (2 pasos)

**Paso 1 de 2 – Cuenta.** Llena nombre completo, correo, contraseña, confirmar contraseña y ciudad, y toca **Continuar**. El formulario no avanza si:

- falta algún campo,
- el correo no es válido,
- la contraseña tiene menos de 6 caracteres,
- las contraseñas no coinciden.

**Paso 2 de 2 – Caracterización.** Escribe tu profesión u ocupación y elige **al menos un interés** del catálogo. También puedes escribir uno nuevo en *Agrega otro interés* y tocar **+**. Toca **Comenzar** para crear la cuenta.

Si el correo ya está registrado, la app muestra *"Ya existe una cuenta con ese correo"*.

### 3. Confirma tu correo

Supabase envía un enlace de confirmación al correo registrado. Ábrelo:

- **Web:** el enlace vuelve a `http://localhost:3000/`, así que la app debe estar corriendo en ese puerto.
- **Android/iOS:** el enlace abre la app con `memorylens://login-callback/`.

Despues de confirmar toca **Ir a iniciar sesión**.

### 4. Iniciar sesión

Escribe correo y contraseña y toca **Entrar**. Si todo va bien se abre **Recuerdos**. Mensajes posibles:

- *"Correo o contraseña incorrectos"*.
- *"Confirma tu correo antes de iniciar sesión"*: aún no se abrió el enlace del paso 3.


### 5. Recuerdos

Es la pantalla principal. Arriba a la derecha el icono de persona abre **Mi perfil**.

- **Sin fotos todavía:** muestra *«Sin conectar»*, el contador *«0 fotos»*, *«Aún no tienes recuerdos»* y el botón **Permitir acceso a la galería**. Si la persona ya tiene fotos guardadas, esta invitación no aparece (la grilla de fotos llega con otra historia; por ahora hay un texto de relleno).
- **Conectar la galería** necesita dos permisos, y sin ambos la app no lee ninguna foto:
  1. Ventana propia *«Memory Lens quiere acceder a tus fotos»* con **No permitir** y **Permitir**. **No permitir** la cierra y deja todo como estaba: la app no vuelve a preguntar por su cuenta.
  2. Con **Permitir** se pide el permiso del sistema. Si lo concede, se abre **Analizando**.
- **Si el sistema dice que no:** aparece *«Sin acceso a tus fotos no hay recuerdos para analizar»* y el botón sigue disponible para intentarlo otra vez. Si el sistema ya no vuelve a preguntar (permiso bloqueado) el mensaje trae **Abrir ajustes**; al volver de los ajustes con el permiso activado la app sigue a **Analizando**.

- **Importación a medias:** si la app se cierra mientras importa, al abrir Recuerdos con el permiso aún activo vuelve sola a **Analizando** y continúa. No vuelve a preguntar nada.

La app solo pide fotos con `permission_handler`, aislado en `GalleryPermissionDataSource`: en Android 13 o superior usa `READ_MEDIA_IMAGES`, en Android 12 o inferior el permiso de almacenamiento y en iOS `NSPhotoLibraryUsageDescription`. En iOS, si la persona elige solo algunas fotos (acceso limitado) cuenta como permiso concedido. En web y escritorio no hay permiso de fotos y se muestra un aviso.

### 6. Analizando

Importa las fotos de la galería a tu espacio en Memory Lens (HU-07):

- **Lee** la lista de fotos del dispositivo con su fecha de captura y guarda cuántas hay (`escaneo_galeria.total_fotos`) antes de subir la primera, para mostrarlo en el progreso.
- **Sube** cada foto como copia JPEG (lado largo hasta 2560 px) más una miniatura de 400 px al bucket privado `fotos`, en `<usuario>/<foto>.jpg` y `<usuario>/thumbs/<foto>.jpg`. La ruta solo depende de la persona y de la foto, así que repetir una subida reemplaza el archivo y no lo duplica.
- **No resube** las que ya están: la fila en `foto` (con su `asset_id`) marca la foto como importada, y cada corrida solo toma las que faltan.
- **Sin conexión:** muestra *«Esperando conexión»* y sigue sola donde quedó cuando vuelve la red. Si tras varios intentos seguidos no entra ninguna foto (por ejemplo, wifi sin internet) muestra el error con **Reintentar**.
- **Fotos que no se pueden leer** (borradas durante la importación, o en la nube sin descargar) se omiten y no detienen al resto.
- **Al terminar** dice *«Listo»* y ofrece **Ver recuerdos**. La barra de progreso con los números llega con su propia historia.

Las fotos originales del teléfono solo se leen: nada del feature puede modificarlas ni borrarlas, y un test lo vigila. El análisis de las fotos llega con otra historia.

### 7. Mi perfil

Muestra tu nombre, profesión, ciudad, correo e intereses. **Cerrar sesión** te devuelve a la bienvenida.

## Errores y falta de conexión

- **Sin conexión:** si el dispositivo pierde la red aparece la franja *«Sin conexión»* arriba de cualquier pantalla y desaparece sola al reconectar. Solo detecta si hay red en el dispositivo; si hay wifi pero no hay internet, la pantalla que falle muestra el mensaje de conexión.
- **Mensajes claros:** todo error llega a la pantalla en español y sin términos técnicos (por ejemplo, *«No pudimos conectarnos. Revisa tu conexión a internet e inténtalo de nuevo.»*). Las pantallas que cargan datos (perfil, intereses) ofrecen **Reintentar**.
- **No se pierde lo escrito:** cuando una acción falla, el formulario queda como estaba. Los campos viven en el `State` de la pantalla y el BLoC solo emite `failure`; nunca los reinicia. Las próximas pantallas de guardar, buscar e importar deben seguir esa regla y usar `ErrorRetryView` para los errores de carga.
- **Registro para el equipo:** los errores técnicos se guardan en la tabla `registro_error` con la pantalla (`pantalla`), la acción (`accion`, el evento del BLoC), el tipo, el mensaje y el stack trace. Los errores normales, como una contraseña incorrecta, no se guardan. La tabla solo permite insertar; el equipo la lee desde Dashboard › Table Editor. Si no hay conexión al fallar, ese error no queda registrado.
- **La app no se cierra:** `main.dart` registra `FlutterError.onError` y `PlatformDispatcher.onError`; un widget que falla se reemplaza por *«Algo salió mal en esta sección»* y un BLoC que falla vuelve a un estado con **Reintentar**.


## Supabase

Las migraciones del modelo de datos están en `supabase/migrations`. Para conectar la carpeta con el proyecto:

```bash
npx supabase link --project-ref vhavapudcqyvwycqizun
npx supabase db push
```

La importación de fotos necesita la migración `20261114120000_import_gallery_photos.sql` (bucket `fotos`, políticas de Storage y columnas nuevas): corre `npx supabase db push` antes de probar **Analizando**.

El registro necesita que **Confirm email** esté encendido (Dashboard › Authentication › Sign In / Providers › Email), igual que `enable_confirmations = true` en `supabase/config.toml`. Los datos del formulario viajan como metadatos de la cuenta, y el trigger `crear_perfil_al_confirmar` guarda el perfil y los intereses cuando se confirma el correo.

En Dashboard › Authentication › URL Configuration, usa `http://localhost:3000` como **Site URL** y agrega `http://localhost:3000/` y `memorylens://login-callback/` a **Redirect URLs**. La versión web corre siempre en el puerto 3000, fijado en `web_dev_config.yaml`.

### Modelo de datos

Basado en el modelo entidad-relación del proyecto:

- **Cuenta y acceso:** `usuario`, `interes`, `usuario_interes`, `escaneo_galeria`.
- **Fotos y etiquetas:** `categoria`, `foto`, `etiqueta`, `foto_etiqueta`.
- **Búsqueda con IA (chat):** `conversacion`, `mensaje`, `resultado_mensaje`.
- **Errores de la app:** `registro_error` (solo inserción, sin lectura desde la app).

**Fotos importadas.** Cada foto importada es una fila de `foto` con `asset_id` (id de la foto en el dispositivo, único por persona), `url_imagen` (la **ruta** del archivo en el bucket `fotos`, no una URL: la URL firmada se pide al mostrarla), `ruta_miniatura` y `fecha_captura` (nula si el dispositivo no tiene fecha). El bucket `fotos` es privado y cada persona solo ve y escribe en su carpeta `<usuario_id>/`. `escaneo_galeria` guarda el total de fotos a procesar y `importacion_finalizada_en`; solo puede haber un escaneo abierto por persona.

`usuario.id` es el mismo id de `auth.users`. La contraseña la guarda Supabase Auth, por eso `usuario` no tiene `contrasena_hash`, y `correo` se copia de `auth.users` con un trigger. Todas las tablas tienen RLS: cada usuario solo ve y modifica sus propias filas; `interes`, `categoria` y `etiqueta` son catálogos.

## Arquitectura

Clean architecture por features, como en el laboratorio del curso:

```text
lib/
  components/            widgets compartidos (botón, error, reintentar, franja sin conexión, logo, chip de interés, app bar)
  theme/                 colores y tema tomados del prototipo de Lovable
  features/
    auth/
      domain/            entidades, contratos de repositorio y casos de uso
      data/              data sources de Supabase e implementaciones de los repositorios
    error_handling/
      domain/            AppException (mensaje en español), ErrorReport y ReportErrorUseCase
      data/              ExceptionMapper (error crudo → mensaje claro) y escritura en registro_error
      ui/                observers del BLoC y de la pantalla actual, y handlers globales de errores
    connectivity/
      domain/            contrato y caso de uso para seguir la conexión
      data/              connectivity_plus detrás de un data source
      ui/                ConnectivityBloc y ConnectivityShell (muestra «Sin conexión»)
    gallery_access/
      domain/            estado del permiso (concedido, negado, bloqueado), contrato y casos de uso para pedirlo, revisarlo y abrir ajustes
      data/              permission_handler y device_info_plus detrás de un data source
    memories/
      domain/            contrato y caso de uso para contar las fotos de la persona
      data/              conteo en la tabla `foto` de Supabase
      ui/                MemoriesBloc, pantalla Recuerdos, ventana propia de permiso y mensajes de acceso negado
    gallery_import/
      domain/            fotos del dispositivo, progreso y escaneo; contratos de repositorio; casos de uso para importar y para saber si hay una importación a medias
      data/              photo_manager (solo lectura) y Supabase (Storage, `foto`, `escaneo_galeria`), cada uno en su propio data source
      ui/                GalleryImportBloc: importa, espera la conexión y reintenta
    analyzing/ui/        pantalla Analizando (importando, esperando conexión, error y «Listo»)
    register/ui/         RegisterBloc y pantalla de registro con caracterización
    welcome/ui/          pantalla inicial con los botones a inicio de sesión y registro
    login/ui/            inicio de sesión
    profile/ui/          resumen del perfil
  injection_container.dart
  main.dart
```

`flutter test` comprueba la navegación de la pantalla inicial, las validaciones del formulario, que el registro guarda el perfil y los intereses, los mensajes de error y de falta de conexión, que los formularios conservan lo escrito tras un fallo, y el registro de errores con su pantalla y acción. También prueba el flujo de la galería: la ventana propia, que sin ella no se pide el permiso del sistema, el permiso negado y el bloqueado con **Abrir ajustes**, y que Recuerdos no muestra la invitación si ya hay fotos. Y prueba la importación: que sube todo con su fecha, que no resube las ya importadas, que guarda el total antes de subir, que continúa tras perder la conexión sin repetir subidas, que omite las fotos ilegibles, que Analizando muestra cada estado y que Recuerdos retoma una importación a medias. Un test revisa que el código del feature nunca llame a lo que escribe o borra en la galería.
