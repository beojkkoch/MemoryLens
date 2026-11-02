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
