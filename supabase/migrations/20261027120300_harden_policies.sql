-- Endurece reglas: el correo de usuario sale de auth.users, los resultados solo
-- apuntan a fotos propias y las etiquetas tienen un largo razonable.

create function public.usuario_correo_desde_auth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.correo := (select email from auth.users where id = new.id);
  return new;
end;
$$;
revoke execute on function public.usuario_correo_desde_auth() from public, anon, authenticated;

create trigger usuario_correo_desde_auth
before insert or update of correo, id on public.usuario
for each row execute function public.usuario_correo_desde_auth();

drop policy "resultado_mensaje: solo el dueño de la conversación" on public.resultado_mensaje;
create policy "resultado_mensaje: solo el dueño de la conversación" on public.resultado_mensaje
  for all to authenticated
  using (exists (
    select 1 from public.mensaje m
    join public.conversacion c on c.id = m.conversacion_id
    where m.id = mensaje_id and c.usuario_id = (select auth.uid())
  ))
  with check (
    exists (
      select 1 from public.mensaje m
      join public.conversacion c on c.id = m.conversacion_id
      where m.id = mensaje_id and c.usuario_id = (select auth.uid())
    )
    and exists (
      select 1 from public.foto f
      where f.id = foto_id and f.usuario_id = (select auth.uid())
    )
  );

alter table public.etiqueta
  add constraint etiqueta_nombre_largo check (char_length(btrim(nombre)) between 1 and 50);
