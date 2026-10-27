-- Cuenta y acceso: usuario, intereses y escaneos de galería.
-- La contraseña la guarda Supabase Auth (auth.users), por eso usuario no tiene contrasena_hash.

create table public.usuario (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  correo text not null unique,
  ciudad text not null,
  profesion text not null,
  creado_en timestamptz not null default now()
);

create table public.interes (
  id int generated always as identity primary key,
  nombre text not null unique
);

create table public.usuario_interes (
  usuario_id uuid not null references public.usuario(id) on delete cascade,
  interes_id int not null references public.interes(id) on delete cascade,
  primary key (usuario_id, interes_id)
);
create index usuario_interes_interes_id_idx on public.usuario_interes(interes_id);

create table public.escaneo_galeria (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuario(id) on delete cascade,
  total_fotos int not null default 0 check (total_fotos >= 0),
  fotos_analizadas int not null default 0 check (fotos_analizadas >= 0),
  etiquetas_revisadas boolean not null default false,
  iniciado_en timestamptz not null default now(),
  finalizado_en timestamptz
);
create index escaneo_galeria_usuario_id_idx on public.escaneo_galeria(usuario_id);

insert into public.interes (nombre) values
  ('Tecnología'), ('Moda'), ('Gastronomía'), ('Lectura'), ('Diseño'), ('Viajes');

grant select, insert, update on public.usuario to authenticated;
grant select on public.interes to anon, authenticated;
grant select, insert, delete on public.usuario_interes to authenticated;
grant select, insert, update, delete on public.escaneo_galeria to authenticated;

alter table public.usuario enable row level security;
alter table public.interes enable row level security;
alter table public.usuario_interes enable row level security;
alter table public.escaneo_galeria enable row level security;

create policy "usuario: ver el propio" on public.usuario
  for select to authenticated using (id = (select auth.uid()));
create policy "usuario: crear el propio" on public.usuario
  for insert to authenticated with check (id = (select auth.uid()));
create policy "usuario: editar el propio" on public.usuario
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "interes: catálogo público" on public.interes
  for select to anon, authenticated using (true);

create policy "usuario_interes: ver los propios" on public.usuario_interes
  for select to authenticated using (usuario_id = (select auth.uid()));
create policy "usuario_interes: elegir los propios" on public.usuario_interes
  for insert to authenticated with check (usuario_id = (select auth.uid()));
create policy "usuario_interes: quitar los propios" on public.usuario_interes
  for delete to authenticated using (usuario_id = (select auth.uid()));

create policy "escaneo_galeria: solo el dueño" on public.escaneo_galeria
  for all to authenticated
  using (usuario_id = (select auth.uid())) with check (usuario_id = (select auth.uid()));
