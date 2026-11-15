-- Análisis de las fotos con IA (HU-08): estado del análisis, embeddings para la búsqueda
-- semántica (HU-21) y la función que guarda el resultado de una foto de una sola vez.

create extension if not exists vector with schema extensions;

-- Toda foto nace pendiente, también las que ya estaban importadas antes de esta migración.
-- 'error' es final: una foto que la IA no pudo describir no se reintenta sola.
alter table public.foto
  add column estado_analisis text not null default 'pendiente'
    check (estado_analisis in ('pendiente', 'listo', 'error')),
  add column analizada_en timestamptz,
  add column embedding_imagen extensions.vector(768),
  add column embedding_texto extensions.vector(768);

comment on column public.foto.texto_alt is
  'Descripción de la foto en español, escrita por la IA (HU-08).';
comment on column public.foto.embedding_imagen is
  'Embedding de la imagen (gemini-embedding-2, 768 dimensiones, normalizado).';
comment on column public.foto.embedding_texto is
  'Embedding de título, descripción, categoría y etiquetas (gemini-embedding-2, 768 dimensiones).';

-- La app busca sus pendientes en cada corrida.
create index foto_pendiente_analisis_idx on public.foto(usuario_id)
  where estado_analisis = 'pendiente';

-- Imagen y texto están en el mismo espacio, así que una consulta de texto se compara con ambas.
create index foto_embedding_imagen_idx on public.foto
  using hnsw (embedding_imagen extensions.vector_cosine_ops);
create index foto_embedding_texto_idx on public.foto
  using hnsw (embedding_texto extensions.vector_cosine_ops);

-- Guarda el análisis de una foto: datos, categoría, etiquetas y embeddings, todo o nada.
-- Corre con los permisos de quien llama (security invoker), así que la RLS de foto impide
-- tocar fotos ajenas. Se puede repetir: reemplaza las etiquetas que la persona no confirmó.
create or replace function public.guardar_analisis_foto(
  p_foto_id uuid,
  p_titulo text,
  p_categoria text,
  p_descripcion text,
  p_etiquetas text[],
  p_embedding_imagen extensions.vector(768),
  p_embedding_texto extensions.vector(768)
) returns void
language plpgsql
security invoker
set search_path = public, extensions
as $$
declare
  v_usuario uuid;
  v_etiquetas text[];
begin
  update foto
     set titulo = left(btrim(p_titulo), 120),
         categoria_id = (select id from categoria where nombre = p_categoria),
         texto_alt = btrim(p_descripcion),
         embedding_imagen = p_embedding_imagen,
         embedding_texto = p_embedding_texto,
         estado_analisis = 'listo',
         analizada_en = now()
   where id = p_foto_id
  returning usuario_id into v_usuario;

  if v_usuario is null then
    raise exception 'Foto % no encontrada', p_foto_id using errcode = 'P0002';
  end if;

  -- Una etiqueta es la misma sin importar mayúsculas ni espacios de más.
  select coalesce(array_agg(distinct nombre), '{}')
    into v_etiquetas
    from (select lower(btrim(e)) as nombre from unnest(p_etiquetas) as e) t
   where char_length(nombre) between 1 and 50;

  insert into etiqueta (nombre)
  select unnest(v_etiquetas)
  on conflict (nombre) do nothing;

  delete from foto_etiqueta
   where foto_id = p_foto_id and not confirmada;

  insert into foto_etiqueta (foto_id, etiqueta_id)
  select p_foto_id, id from etiqueta where nombre = any (v_etiquetas)
  on conflict (foto_id, etiqueta_id) do nothing;

  -- El progreso del escaneo abierto es el número real de fotos ya analizadas.
  update escaneo_galeria
     set fotos_analizadas = (
       select count(*) from foto
        where usuario_id = v_usuario and estado_analisis = 'listo'
     )
   where usuario_id = v_usuario and finalizado_en is null;
end;
$$;

-- Marca una foto que la IA no pudo describir (bloqueada o ilegible) para no frenar al resto.
create or replace function public.marcar_error_analisis_foto(p_foto_id uuid)
returns void
language sql
security invoker
set search_path = public
as $$
  update foto
     set estado_analisis = 'error', analizada_en = now()
   where id = p_foto_id and estado_analisis = 'pendiente';
$$;

revoke execute on function public.guardar_analisis_foto from public, anon;
revoke execute on function public.marcar_error_analisis_foto from public, anon;
grant execute on function public.guardar_analisis_foto to authenticated;
grant execute on function public.marcar_error_analisis_foto to authenticated;
