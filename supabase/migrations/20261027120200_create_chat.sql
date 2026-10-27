-- Búsqueda con IA (chat): conversación, mensaje y las fotos que muestra cada mensaje.

create table public.conversacion (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuario(id) on delete cascade,
  titulo text not null,
  creada_en timestamptz not null default now(),
  actualizada_en timestamptz not null default now()
);
create index conversacion_usuario_id_idx on public.conversacion(usuario_id);

create table public.mensaje (
  id uuid primary key default gen_random_uuid(),
  conversacion_id uuid not null references public.conversacion(id) on delete cascade,
  rol text not null check (rol in ('user', 'assistant')),
  texto text not null,
  creado_en timestamptz not null default now()
);
create index mensaje_conversacion_id_idx on public.mensaje(conversacion_id);

create table public.resultado_mensaje (
  mensaje_id uuid not null references public.mensaje(id) on delete cascade,
  foto_id uuid not null references public.foto(id) on delete cascade,
  posicion int not null check (posicion >= 0),
  primary key (mensaje_id, foto_id)
);
create index resultado_mensaje_foto_id_idx on public.resultado_mensaje(foto_id);

grant select, insert, update, delete on public.conversacion to authenticated;
grant select, insert, update, delete on public.mensaje to authenticated;
grant select, insert, update, delete on public.resultado_mensaje to authenticated;

alter table public.conversacion enable row level security;
alter table public.mensaje enable row level security;
alter table public.resultado_mensaje enable row level security;

create policy "conversacion: solo el dueño" on public.conversacion
  for all to authenticated
  using (usuario_id = (select auth.uid())) with check (usuario_id = (select auth.uid()));

create policy "mensaje: solo el dueño de la conversación" on public.mensaje
  for all to authenticated
  using (exists (
    select 1 from public.conversacion c
    where c.id = conversacion_id and c.usuario_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.conversacion c
    where c.id = conversacion_id and c.usuario_id = (select auth.uid())
  ));

create policy "resultado_mensaje: solo el dueño de la conversación" on public.resultado_mensaje
  for all to authenticated
  using (exists (
    select 1 from public.mensaje m
    join public.conversacion c on c.id = m.conversacion_id
    where m.id = mensaje_id and c.usuario_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.mensaje m
    join public.conversacion c on c.id = m.conversacion_id
    where m.id = mensaje_id and c.usuario_id = (select auth.uid())
  ));
