-- Crea el perfil cuando Supabase Auth confirma el correo. Los datos del formulario
-- llegan en raw_user_meta_data al registrarse, antes de que exista una sesión.
-- raw_user_meta_data lo escribe el cliente, por eso se valida todo: un error aquí
-- impediría confirmar la cuenta.

create function public.crear_perfil_al_confirmar()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_datos jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_nombre text := nullif(btrim(v_datos->>'nombre'), '');
  v_ciudad text := nullif(btrim(v_datos->>'ciudad'), '');
  v_profesion text := nullif(btrim(v_datos->>'profesion'), '');
  v_intereses jsonb := case when jsonb_typeof(v_datos->'intereses') = 'array'
    then v_datos->'intereses' else '[]'::jsonb end;
  v_nuevos jsonb := case when jsonb_typeof(v_datos->'intereses_nuevos') = 'array'
    then v_datos->'intereses_nuevos' else '[]'::jsonb end;
begin
  -- Cuentas creadas fuera de la app, por ejemplo desde el dashboard.
  if v_nombre is null or v_ciudad is null or v_profesion is null then
    return new;
  end if;

  insert into public.usuario (id, nombre, correo, ciudad, profesion)
  values (new.id, v_nombre, new.email, v_ciudad, v_profesion)
  on conflict (id) do nothing;

  insert into public.interes (nombre)
  select btrim(valor)
  from jsonb_array_elements_text(v_nuevos) as valor
  where char_length(btrim(valor)) between 1 and 40
  on conflict (nombre) do nothing;

  insert into public.usuario_interes (usuario_id, interes_id)
  select new.id, i.id
  from public.interes i
  where i.id::text in (select jsonb_array_elements_text(v_intereses))
     or i.nombre in (select btrim(valor) from jsonb_array_elements_text(v_nuevos) as valor)
  on conflict do nothing;

  return new;
end;
$$;
revoke execute on function public.crear_perfil_al_confirmar() from public, anon, authenticated;

create trigger crear_perfil_al_confirmar_update
after update on auth.users
for each row
when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
execute function public.crear_perfil_al_confirmar();

create trigger crear_perfil_al_confirmar_insert
after insert on auth.users
for each row
when (new.email_confirmed_at is not null)
execute function public.crear_perfil_al_confirmar();
