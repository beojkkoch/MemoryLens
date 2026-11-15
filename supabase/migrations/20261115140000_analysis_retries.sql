-- Reintentos del análisis (HU-10, CA6): una foto que la IA no logra describir se reintenta
-- hasta 3 veces. La cuenta vive en la base, así que se respeta aunque la app se cierre.
-- Después de 3 intentos la foto queda en 'error' («No analizada») y no frena al resto.

alter table public.foto
  add column intentos_analisis int not null default 0 check (intentos_analisis >= 0);

comment on column public.foto.intentos_analisis is
  'Intentos fallidos de análisis. Al llegar a 3 la foto pasa a estado_analisis = error (HU-10).';

-- Suma un intento fallido y devuelve el estado que queda: 'pendiente' si todavía se puede
-- reintentar, 'error' si ya se agotaron los intentos. Una foto que no está pendiente (ya
-- analizada por otra corrida, por ejemplo) no cambia.
create or replace function public.registrar_fallo_analisis_foto(p_foto_id uuid)
returns text
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_estado text;
begin
  update foto
     set intentos_analisis = intentos_analisis + 1,
         estado_analisis = case when intentos_analisis + 1 >= 3 then 'error' else 'pendiente' end,
         analizada_en = case when intentos_analisis + 1 >= 3 then now() else analizada_en end
   where id = p_foto_id and estado_analisis = 'pendiente'
  returning estado_analisis into v_estado;

  if v_estado is null then
    select estado_analisis into v_estado from foto where id = p_foto_id;
  end if;
  return coalesce(v_estado, 'error');
end;
$$;

revoke execute on function public.registrar_fallo_analisis_foto from public, anon;
grant execute on function public.registrar_fallo_analisis_foto to authenticated;
