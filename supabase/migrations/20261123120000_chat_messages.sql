-- Chat de búsqueda con IA (HU-20, HU-23, HU-24, HU-25): guardar los mensajes de una
-- conversación en la cuenta y una búsqueda provisional por palabras. Las tablas ya existen
-- (create_chat); borrar una conversación es un delete por RLS y el cascade quita sus mensajes
-- y resultados sin tocar las fotos (HU-24, CA8).

-- Guarda un mensaje y las fotos que muestra, todo o nada. Corre con los permisos de quien
-- llama (security invoker): la RLS impide escribir en conversaciones ajenas (HU-25, CA3) y
-- mostrar fotos de otra persona.
--
-- La conversación se crea con su primer mensaje, con el id que eligió la app, así una
-- conversación vacía nunca llega al historial (HU-23, CA4). El título solo se escribe al
-- crearla. Cada mensaje sube actualizada_en, que ordena el historial (HU-24, CA2).
create or replace function public.guardar_mensaje_chat(
  p_conversacion_id uuid,
  p_titulo text,
  p_rol text,
  p_texto text,
  p_fotos uuid[] default '{}'
) returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_mensaje_id uuid;
  v_titulo text;
begin
  if p_rol is null or p_rol not in ('user', 'assistant') then
    raise exception 'Rol % no válido', p_rol using errcode = '22023';
  end if;
  if btrim(coalesce(p_texto, '')) = '' then
    raise exception 'El mensaje está vacío' using errcode = '22023';
  end if;

  v_titulo := coalesce(nullif(left(btrim(p_titulo), 60), ''), 'Nueva búsqueda');

  insert into conversacion (id, usuario_id, titulo)
  values (p_conversacion_id, auth.uid(), v_titulo)
  on conflict (id) do nothing;

  insert into mensaje (conversacion_id, rol, texto)
  values (p_conversacion_id, p_rol, btrim(p_texto))
  returning id into v_mensaje_id;

  -- La posición conserva el orden en que llegaron las fotos.
  insert into resultado_mensaje (mensaje_id, foto_id, posicion)
  select v_mensaje_id, f.foto_id, (f.posicion - 1)::int
    from unnest(coalesce(p_fotos, '{}')) with ordinality as f(foto_id, posicion)
  on conflict do nothing;

  update conversacion set actualizada_en = now() where id = p_conversacion_id;

  return v_mensaje_id;
end;
$$;

revoke execute on function public.guardar_mensaje_chat from public, anon;
grant execute on function public.guardar_mensaje_chat to authenticated;

-- Búsqueda provisional por palabras, hasta que HU-21 la reemplace por una búsqueda
-- semántica. Devuelve las fotos analizadas de la persona (la RLS de foto se encarga) cuyo
-- título, descripción, tipo de compra, categoría o etiquetas contienen alguna de las
-- palabras, primero las que coinciden con más palabras y luego las más recientes.
-- Ignora mayúsculas y tildes; la app ya manda las palabras limpias.
create or replace function public.buscar_fotos_por_palabras(
  p_palabras text[],
  p_limite int default 12
) returns table (id uuid)
language sql
stable
security invoker
set search_path = public
as $$
  select f.id
    from foto f
    left join categoria c on c.id = f.categoria_id
    cross join lateral (
      select translate(
        lower(
          coalesce(f.titulo, '') || ' ' || coalesce(f.texto_alt, '') || ' '
          || coalesce(f.tipo_compra, '') || ' ' || coalesce(c.nombre, '') || ' '
          || coalesce((
            select string_agg(e.nombre, ' ')
              from foto_etiqueta fe
              join etiqueta e on e.id = fe.etiqueta_id
             where fe.foto_id = f.id
          ), '')
        ),
        'áéíóúüñ', 'aeiouun'
      ) as texto
    ) h
    cross join lateral (
      select count(*) as coincidencias
        from unnest(coalesce(p_palabras, '{}')) as w(palabra)
       where btrim(w.palabra) <> ''
         and strpos(
           h.texto,
           translate(lower(btrim(w.palabra)), 'áéíóúüñ', 'aeiouun')
         ) > 0
    ) s
   where f.estado_analisis = 'listo'
     and s.coincidencias > 0
   order by s.coincidencias desc, f.fecha_captura desc nulls last, f.id
   limit least(greatest(coalesce(p_limite, 12), 1), 12);
$$;

revoke execute on function public.buscar_fotos_por_palabras from public, anon;
grant execute on function public.buscar_fotos_por_palabras to authenticated;
