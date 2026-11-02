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

La app tiene **un solo tipo de usuario**: la persona dueña de la galería. No hay roles ni administradores; cada usuario solo ve sus propios datos.

```text
Bienvenida ──► Registro (paso 1 → paso 2) ──► Confirma tu correo ──► Iniciar sesión ──► Mi perfil
     │                                                                    ▲              │
     └──────────────── Continuar con correo electrónico ─────────────────┘              │
     ▲                                                                                   │
     └───────────────────────────────── Cerrar sesión ◄─────────────────────────────────┘
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

Escribe correo y contraseña y toca **Entrar**. Mensajes posibles:

- *"Correo o contraseña incorrectos"*.
- *"Confirma tu correo antes de iniciar sesión"*: aún no se abrió el enlace del paso 3.


### 5. Mi perfil

Muestra tu nombre, profesión, ciudad, correo e intereses. **Cerrar sesión** te devuelve a la bienvenida.


## Supabase

Las migraciones del modelo de datos están en `supabase/migrations`. Para conectar la carpeta con el proyecto:

```bash
npx supabase link --project-ref vhavapudcqyvwycqizun
npx supabase db push
```

El registro necesita que **Confirm email** esté encendido (Dashboard › Authentication › Sign In / Providers › Email), igual que `enable_confirmations = true` en `supabase/config.toml`. Los datos del formulario viajan como metadatos de la cuenta, y el trigger `crear_perfil_al_confirmar` guarda el perfil y los intereses cuando se confirma el correo.

En Dashboard › Authentication › URL Configuration, usa `http://localhost:3000` como **Site URL** y agrega `http://localhost:3000/` y `memorylens://login-callback/` a **Redirect URLs**. La versión web corre siempre en el puerto 3000, fijado en `web_dev_config.yaml`.

### Modelo de datos

Basado en el modelo entidad-relación del proyecto:

- **Cuenta y acceso:** `usuario`, `interes`, `usuario_interes`, `escaneo_galeria`.
- **Fotos y etiquetas:** `categoria`, `foto`, `etiqueta`, `foto_etiqueta`.
- **Búsqueda con IA (chat):** `conversacion`, `mensaje`, `resultado_mensaje`.

`usuario.id` es el mismo id de `auth.users`. La contraseña la guarda Supabase Auth, por eso `usuario` no tiene `contrasena_hash`, y `correo` se copia de `auth.users` con un trigger. Todas las tablas tienen RLS: cada usuario solo ve y modifica sus propias filas; `interes`, `categoria` y `etiqueta` son catálogos.

## Arquitectura

Clean architecture por features, como en el laboratorio del curso:

```text
lib/
  components/            widgets compartidos (botón, error, logo, chip de interés, app bar)
  theme/                 colores y tema tomados del prototipo de Lovable
  features/
    auth/
      domain/            entidades, contratos de repositorio y casos de uso
      data/              data sources de Supabase e implementaciones de los repositorios
    register/ui/         RegisterBloc y pantalla de registro con caracterización
    welcome/ui/          pantalla inicial con los botones a inicio de sesión y registro
    login/ui/            inicio de sesión (pendiente)
    profile/ui/          resumen del perfil (pendiente)
  injection_container.dart
  main.dart
```

`flutter test` comprueba la navegación de la pantalla inicial, las validaciones del formulario y que el registro guarda el perfil y los intereses.
