-- Fotos y etiquetas: categoría, foto, etiqueta y la etiqueta asignada a cada foto.

create table public.categoria (
  id int generated always as identity primary key,
  nombre text not null unique
);

create table public.foto (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuario(id) on delete cascade,
  categoria_id int references public.categoria(id) on delete set null,
  url_imagen text not null,
  texto_alt text,
  titulo text,
  color text check (color ~ '^#[0-9A-Fa-f]{6}$'),
  fecha_captura timestamptz,
  origen text,
  tipo_compra text,
  monto numeric(12, 2)
);
create index foto_usuario_id_idx on public.foto(usuario_id);
create index foto_categoria_id_idx on public.foto(categoria_id);

create table public.etiqueta (
  id int generated always as identity primary key,
  nombre text not null unique
);

create table public.foto_etiqueta (
  foto_id uuid not null references public.foto(id) on delete cascade,
  etiqueta_id int not null references public.etiqueta(id) on delete cascade,
  confirmada boolean not null default false,
  primary key (foto_id, etiqueta_id)
);
create index foto_etiqueta_etiqueta_id_idx on public.foto_etiqueta(etiqueta_id);

insert into public.categoria (nombre) values
  ('Factura'), ('Comida'), ('Lugar'), ('Viaje'), ('Mascotas'), ('Personas'), ('Arte'), ('Trabajo');

grant select on public.categoria to authenticated;
grant select, insert, update, delete on public.foto to authenticated;
grant select, insert on public.etiqueta to authenticated;
grant select, insert, update, delete on public.foto_etiqueta to authenticated;

alter table public.categoria enable row level security;
alter table public.foto enable row level security;
alter table public.etiqueta enable row level security;
alter table public.foto_etiqueta enable row level security;

create policy "categoria: catálogo" on public.categoria
  for select to authenticated using (true);

create policy "foto: solo el dueño" on public.foto
  for all to authenticated
  using (usuario_id = (select auth.uid())) with check (usuario_id = (select auth.uid()));

create policy "etiqueta: leer catálogo" on public.etiqueta
  for select to authenticated using (true);
create policy "etiqueta: crear nuevas" on public.etiqueta
  for insert to authenticated with check (true);

create policy "foto_etiqueta: solo el dueño de la foto" on public.foto_etiqueta
  for all to authenticated
  using (exists (
    select 1 from public.foto f
    where f.id = foto_id and f.usuario_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.foto f
    where f.id = foto_id and f.usuario_id = (select auth.uid())
  ));
