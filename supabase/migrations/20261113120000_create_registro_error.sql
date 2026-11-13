-- Bitácora de errores técnicos de la app (HU-35). La app guarda aquí la pantalla y la
-- acción donde falló algo; el equipo la consulta desde el dashboard de Supabase.

create table public.registro_error (
  id bigint generated always as identity primary key,
  -- Queda en null cuando el error ocurre antes de iniciar sesión (login, registro).
  usuario_id uuid default auth.uid(),
  pantalla text not null check (char_length(pantalla) <= 200),
  accion text not null check (char_length(accion) <= 200),
  tipo text not null check (char_length(tipo) <= 200),
  mensaje text not null check (char_length(mensaje) <= 2000),
  stack_trace text check (char_length(stack_trace) <= 8000),
  plataforma text check (char_length(plataforma) <= 50),
  creado_en timestamptz not null default now()
);

alter table public.registro_error enable row level security;

-- Se permite insertar sin sesión porque login y registro fallan antes de tener una.
-- No hay política de lectura: solo el equipo ve la tabla (rol de servicio).
grant insert on public.registro_error to anon, authenticated;

create policy "registro_error: cualquiera puede registrar" on public.registro_error
  for insert to anon, authenticated
  with check (usuario_id is null or usuario_id = (select auth.uid()));
