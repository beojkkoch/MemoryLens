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

## Guía rápida para probar la app

### Requisitos

- **Android o iOS** (dispositivo real o emulador) con algunas fotos en la galería. Los flujos de galería, importación y análisis solo funcionan en móvil: en web y escritorio no hay permiso de fotos y la app lo avisa.
- Para que el análisis muestre datos de factura, conviene tener en la galería al menos **una foto de un recibo o factura** con el total visible, además de fotos de comida, lugares, mascotas, etc.
- Conexión a internet (Supabase y la IA corren en la nube; el proyecto ya está desplegado, no hay que configurar nada).

### Cuenta de prueba

Ya confirmada y con fotos analizadas, para entrar sin registrarse:

| Correo | Contraseña |
|---|---|
| `<jhondoetitor@gmail.com>` | `<Contrasena@123>` |

Para crear una cuenta propia: **Regístrate** → llena los dos pasos (la contraseña debe tener al menos 6 caracteres) → abre el enlace que llega al correo **desde el mismo teléfono** (abre la app con `memorylens://login-callback/`) → **Ir a iniciar sesión**. Sin confirmar el correo el login responde *«Confirma tu correo antes de iniciar sesión»*.

### Recorrido sugerido

1. **Bienvenida** → **Continuar con correo electrónico** → inicia sesión con la cuenta de prueba.
2. **Recuerdos**: las fotos analizadas agrupadas por día (*«Hoy»*, *«Ayer»*, fechas). Desplázate hacia abajo para cargar más.
3. Toca una foto → **Detalle**: título, descripción, fecha y categoría escritos por la IA. Abre una **factura** para ver *Tipo de compra* y *Monto total*.
4. En el detalle cambia la categoría o el monto y toca **Hecho**; al volver a abrir la foto se ve lo corregido.
5. Toma o descarga una foto nueva en el teléfono y vuelve a la app: aparece *«Analizando N fotos nuevas…»* y luego *«N nuevas fotos analizadas.»*.
6. Ícono de persona → **Mi perfil** → **Cerrar sesión**.
7. Con una **cuenta nueva** (sin fotos): **Permitir acceso a la galería** → **Permitir** en la ventana de la app y en la del sistema → **Analizando** muestra el progreso de importación y análisis → al llegar al 100 % abre **Recuerdos**.

Para probar errores: activa el modo avión en cualquier pantalla (aparece *«Sin conexión»*, y Analizando espera y sigue solo al volver la red), o niega el permiso de fotos en el paso 7 (aparece el mensaje y, si queda bloqueado, **Abrir ajustes**).

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

- **Sin fotos todavía:** muestra *«Sin conectar»*, el contador *«0 fotos»*, *«Aún no tienes recuerdos»* y el botón **Permitir acceso a la galería**. Si la persona ya tiene fotos guardadas, esta invitación no aparece.
- **Línea de tiempo (HU-12):** las fotos ya analizadas se ven en una cuadrícula de 3 columnas con miniaturas cuadradas, agrupadas por el día en que se tomaron (`fecha_captura`, no la fecha de importación): *«Hoy»*, *«Ayer»* y luego fechas como *«15 jun 2024»*, del día más reciente al más antiguo, y dentro de cada día de la más reciente a la más antigua. Las fotos sin fecha van al final en *«Sin fecha»*. Bajo el título *«Recuerdos»* aparece el mes de la foto más reciente (*«Junio 2024»*), y a la derecha el total de fotos analizadas (*«128 fotos»*, *«1 foto»*), que se actualiza cuando termina el análisis de fotos nuevas.
  - Las miniaturas salen del bucket privado con URLs firmadas que duran 24 h. Cada página firma solo sus propias fotos, en una sola llamada.
  - **Carga por partes (HU-15):** al abrir Recuerdos solo llegan las 60 fotos más recientes (`GetMemoriesUseCase.pageSize`), junto con el total y el conteo de analizadas, pedidos en paralelo. A unos 800 px del final se pide la página siguiente sin frenar el desplazamiento, y mientras llega se ve un indicador al final. Solo se construyen las miniaturas cercanas a la pantalla, y siempre son miniaturas de 400 px, nunca la foto original. Si una página falla, lo ya cargado se queda y el siguiente desplazamiento vuelve a intentarlo. Cuando termina el análisis de fotos nuevas (HU-11) se piden las fotos analizadas en esa corrida (por `foto.analizada_en`, con una hora de margen por si el reloj del teléfono no coincide con el del servidor) que caen dentro de lo ya cargado, y cada una aparece bajo su día aunque se haya tomado hace años. Las más antiguas que lo cargado llegan con las páginas siguientes. No se pierde nada de lo cargado, así la cuadrícula no salta al inicio.
  - Mientras carga se ven cuadros grises. Si la carga falla aparece **Reintentar**, y una miniatura que no carga se ve como un cuadro gris con un ícono de imagen.
  - Cada miniatura se anuncia como *«Abrir [título]»*. Al tocarla se abre el **Detalle de foto** (`/foto`, con el id de la foto como argumento), y al volver la cuadrícula sigue en la misma posición.
  - Si no hay ninguna foto analizada no se muestra una cuadrícula vacía sino la galería vacía.
- **Conectar la galería** necesita dos permisos, y sin ambos la app no lee ninguna foto:
  1. Ventana propia *«Memory Lens quiere acceder a tus fotos»* con **No permitir** y **Permitir**. **No permitir** la cierra y deja todo como estaba: la app no vuelve a preguntar por su cuenta.
  2. Con **Permitir** se pide el permiso del sistema. Si lo concede, se abre **Analizando**.
- **Si el sistema dice que no:** aparece *«Sin acceso a tus fotos no hay recuerdos para analizar»* y el botón sigue disponible para intentarlo otra vez. Si el sistema ya no vuelve a preguntar (permiso bloqueado) el mensaje trae **Abrir ajustes**; al volver de los ajustes con el permiso activado la app sigue a **Analizando**.

- **Importación a medias:** si la app se cierra mientras importa, al abrir Recuerdos con el permiso aún activo vuelve sola a **Analizando** y continúa. No vuelve a preguntar nada.
- **Fotos nuevas (HU-11):** con la galería ya conectada, cada vez que se abre Recuerdos o la app vuelve al frente se comparan las fotos del dispositivo con las ya importadas (`CountNewPhotosUseCase`). Si hay nuevas, se importan y analizan ahí mismo, sin pasar por **Analizando**, con los mismos pasos de HU-07 y HU-08 (`ImportNewPhotosUseCase`): no se resube ni se reanaliza nada ya procesado. Mientras tanto se ve *«Analizando N fotos nuevas…»*, y al terminar el aviso *«N nuevas fotos analizadas.»* con **Revisar etiquetas** (por ahora solo cierra el aviso, hasta que exista la revisión de etiquetas). N cuenta solo las fotos que la IA sí describió. Sin fotos nuevas no aparece nada, y si la persona retiró el permiso en el sistema la galería ni se lee. Si se corta la conexión, lo hecho queda guardado y la siguiente apertura sigue.

La app solo pide fotos con `permission_handler`, aislado en `GalleryPermissionDataSource`: en Android 13 o superior usa `READ_MEDIA_IMAGES`, en Android 12 o inferior el permiso de almacenamiento y en iOS `NSPhotoLibraryUsageDescription`. En iOS, si la persona elige solo algunas fotos (acceso limitado) cuenta como permiso concedido. En web y escritorio no hay permiso de fotos y se muestra un aviso.

### 6. Analizando

Importa las fotos de la galería a tu espacio en Memory Lens (HU-07):

- **Lee** la lista de fotos del dispositivo con su fecha de captura y guarda cuántas hay (`escaneo_galeria.total_fotos`) antes de subir la primera, para mostrarlo en el progreso.
- **Sube** cada foto como copia JPEG (lado largo hasta 2560 px) más una miniatura de 400 px al bucket privado `fotos`, en `<usuario>/<foto>.jpg` y `<usuario>/thumbs/<foto>.jpg`. La ruta solo depende de la persona y de la foto, así que repetir una subida reemplaza el archivo y no lo duplica.
- **No resube** las que ya están: la fila en `foto` (con su `asset_id`) marca la foto como importada, y cada corrida solo toma las que faltan.
- **Sin conexión:** muestra *«Esperando conexión»* y sigue sola donde quedó cuando vuelve la red. Si tras varios intentos seguidos no entra ninguna foto (por ejemplo, wifi sin internet) muestra el error con **Reintentar**.
- **Fotos que no se pueden leer** (borradas durante la importación, o en la nube sin descargar) se omiten y no detienen al resto.
- **Después la IA describe cada foto** (HU-08), con el título *«Analizando tu galería…»*. Gemini escribe en español un **título**, una **categoría** del catálogo (Factura, Comida, Lugar, Viaje, Mascotas, Personas, Arte, Trabajo), entre 3 y 8 **etiquetas** y una descripción corta (`foto.texto_alt`). Las etiquetas entran a `foto_etiqueta` con `confirmada = false`.
- **Facturas (HU-09):** si la foto queda en **Factura**, la misma llamada lee el **tipo de compra** (por ejemplo *Cafetería*), el **monto total** y su **moneda** (código ISO, como `COP` o `USD`), y los guarda en `foto.tipo_compra`, `foto.monto` y `foto.moneda`. Si el símbolo es solo «$», la IA usa la ciudad del perfil para saber de qué país es. Lo que no se lee con claridad queda vacío: monto y moneda van juntos o no van, y una foto que no es factura nunca los tiene (la función SQL lo hace cumplir). El tipo de compra también entra como etiqueta y en el texto de la búsqueda. Para mostrarlos, `InvoiceDetails.label()` arma el chip *«Factura · Cafetería · $23.10»* y `Money.format()` da el monto con el formato de su moneda (`$23.10`, `$23.100`, `€1.234,50`).
- **Embeddings para la búsqueda (HU-21):** cada foto guarda dos vectores de 768 dimensiones de `gemini-embedding-2`, uno de la imagen (`embedding_imagen`) y otro de su texto (`embedding_texto`). Los dos están en el mismo espacio, así que una consulta en texto se compara con ambos.
- **No se paga dos veces:** `foto.estado_analisis` (`pendiente`, `listo`, `error`) marca lo que ya se hizo. Cada corrida solo envía las pendientes, 4 por llamada y 2 llamadas a la vez (128 fotos son 32 llamadas, unos 3 a 4 minutos).
- **Límite del plan gratuito:** si Gemini pide esperar, la app espera lo que indica y repite la llamada, hasta 4 veces. Si sigue ocupado, muestra el error con **Reintentar**. Sin conexión hace lo mismo que la importación: *«Esperando conexión»* y sigue sola.
- **Reintentos (HU-10):** si la IA no logra describir una foto, o una llamada falla por un error del servidor, la foto se reintenta sola hasta **3 veces**. La cuenta vive en `foto.intentos_analisis`, así que se respeta aunque la app se cierre. Una foto que sigue fallando queda en `error` (*«No analizada»*) y no frena al resto. Una foto que ya no está en el bucket pasa a `error` de una vez. Perder la conexión o un Gemini que sigue ocupado no gasta intentos: el análisis espera.
- **Reintentar las no analizadas (HU-10):** si al terminar quedan fotos *«No analizadas»*, la pantalla no salta sola a Recuerdos: ofrece **Reintentar**, que las devuelve a la cola con sus 3 intentos (`reintentar_fotos_no_analizadas`) y analiza solo esas, o **Ver mis recuerdos**. Si todas salen bien, abre Recuerdos como siempre.
- **Progreso real (HU-10):** un anillo con el porcentaje, *«Analizadas X de N fotos»* y, si las hay, *«N fotos no analizadas»*. El porcentaje cuenta las fotos procesadas, analizadas o no, y solo llega a 100 % cuando no queda ninguna en cola. Los números cambian cada vez que termina una llamada a la IA, no con una animación, y además cada 4 s se vuelven a leer los conteos guardados en la cuenta, así la pantalla nunca pasa más de 5 s sin novedades aunque una llamada tarde. Mientras importa, el mismo anillo muestra *«Preparadas X de N fotos»*.
- **A medias:** si la app se cierra durante el análisis, Recuerdos vuelve sola a **Analizando**, igual que con una importación pendiente, y el anillo arranca desde lo que ya está guardado.
- **Al llegar al 100 %** la pantalla muestra *«¡Listo!»* un momento y abre **Recuerdos** sola.

Las fotos originales del teléfono solo se leen: nada del feature puede modificarlas ni borrarlas, y un test lo vigila.

La clave de la IA nunca está en la app. La Edge Function `analizar-fotos` (`supabase/functions/analizar-fotos`) recibe hasta 4 ids, baja las fotos del bucket con el token de la persona (la RLS aplica), llama a Gemini y guarda todo con la función SQL `guardar_analisis_foto`. Plan gratuito de Google AI Studio: Google puede usar lo que se envía para mejorar sus productos.

### 7. Detalle de foto

Se abre desde Recuerdos, y más adelante desde el chat, con el id de la foto (HU-28):

- Arriba, la foto en grande ocupa cerca del 70 % de la pantalla y un degradado la une al panel de abajo. Es la copia grande del bucket (hasta 2560 px), firmada solo al abrir el detalle y con validez de 1 h; nunca la miniatura. La foto se ve completa, sin recortar, para que una factura se pueda leer entera.
- El panel muestra *«ANÁLISIS DE IA»*, el título con un ícono de etiqueta y la descripción que escribió la IA (`foto.texto_alt`).
- Debajo, en dos columnas: **Fecha** (*«14 jun 2024, 10:27»*, no se puede editar), **Categoría**, **Tipo de compra** y **Monto total**. Tipo de compra y Monto total solo aparecen en fotos de categoría **Factura** (HU-29): una foto de paisaje no muestra datos de compra. Se muestra lo que está guardado en la foto, sea de la IA o corregido por la persona, y *«—»* donde no hay dato.
- El botón de volver, arriba a la izquierda, regresa a la pantalla anterior.
- **Corregir los datos (HU-30):** la categoría se elige del catálogo del sistema (tabla `categoria`) y no puede quedar vacía. En una factura también se corrigen el tipo de compra (hasta 40 caracteres) y el monto. El monto muestra el símbolo de su moneda, solo acepta números con hasta 2 decimales (con punto o coma) y no deja escribir un signo menos ni guardar 0. Una factura que no tenía monto usa COP (`PhotoEdit.defaultCurrency`).
  - Al cambiar a Factura, los campos de compra aparecen vacíos para completarlos. Al cambiar a otra categoría se ocultan, pero sus valores se conservan hasta tocar **Hecho**, así que volver a Factura antes de guardar no pierde nada. Al guardar fuera de Factura, `PhotoEdit.toSave()` los borra (HU-29).
  - **Hecho** guarda con la función SQL `guardar_correccion_foto`, que vuelve a validar todo, borra los datos de compra fuera de Factura y reemplaza la etiqueta del tipo de compra anterior por la corregida, ya confirmada. Mientras guarda, el botón muestra la carga; si falla, se ve el error y la persona sigue en el detalle con lo que escribió. Si sale bien, se abre **Recuerdos**.
  - Las correcciones quedan en las mismas columnas que escribe la IA (`categoria_id`, `tipo_compra`, `monto`, `moneda`), así que al volver a abrir la foto se ven, y los filtros y el chat las usan. El embedding de texto de la foto no se recalcula al corregir.
- Si la foto no existe o es de otra persona (la RLS no la deja ver), aparece *«Foto no encontrada»* con **Volver**. Si la carga falla, el mensaje trae **Reintentar**.

### 8. Mi perfil

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

Las correcciones del detalle necesitan la migración `20261115160000_save_photo_corrections.sql` (`guardar_correccion_foto`): corre `npx supabase db push`.

El análisis con IA necesita cuatro migraciones: `20261115120000_analyze_photos.sql` (pgvector, `estado_analisis`, embeddings y las funciones `guardar_analisis_foto` y `marcar_error_analisis_foto`), `20261115130000_invoice_details.sql` (moneda de las facturas; también devuelve a la cola, una sola vez, las facturas ya analizadas para leerles el monto) `20261115140000_analysis_retries.sql` (intentos por foto y `registrar_fallo_analisis_foto`) y `20261115150000_retry_failed_photos.sql` (`reintentar_fotos_no_analizadas`, para el botón **Reintentar**). Además necesita la Edge Function con su clave de Gemini. La clave se saca gratis en [Google AI Studio](https://aistudio.google.com/apikey):

```bash
npx supabase db push
npx supabase secrets set GEMINI_API_KEY=<tu-clave>
npx supabase functions deploy analizar-fotos
```

El modelo por defecto es `gemini-3.8-flash`. Para cambiarlo sin tocar código: `npx supabase secrets set GEMINI_MODEL=<modelo>`. Los límites del plan gratuito se ven en AI Studio. Las pruebas de la función corren con `npx deno test --allow-env supabase/functions/analizar-fotos`.

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
      domain/            línea de tiempo (grupos por día), conteos y caso de uso para cargar las fotos analizadas por páginas
      data/              fotos analizadas de la tabla `foto` con miniaturas firmadas
      ui/                MemoriesBloc, pantalla Recuerdos con la cuadrícula, ventana propia de permiso y avisos de acceso negado y fotos nuevas
    photo_analysis/
      domain/            progreso, facturas (InvoiceDetails, Money) y casos de uso para analizar, reintentar y saber si hay análisis pendiente
      data/              llamada a la Edge Function analizar-fotos y a las funciones SQL de reintento
      ui/                PhotoAnalysisBloc: analiza por lotes, espera la conexión y respeta el límite de la IA
    photo_detail/
      domain/            detalle de una foto, corrección (PhotoEdit) y casos de uso para leerla, listar categorías y guardar
      data/              foto con su análisis, imagen grande firmada y guardar_correccion_foto
      ui/                PhotoDetailBloc y pantalla de detalle con el panel de análisis editable
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
