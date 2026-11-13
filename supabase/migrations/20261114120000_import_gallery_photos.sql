-- Importación de la galería (HU-07): bucket privado de fotos, políticas de Storage por
-- carpeta de usuario y columnas para saber qué foto del dispositivo ya se importó.

-- Bucket privado. La app sube una copia JPEG normalizada y una miniatura, nunca el original.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', false, 10485760, array['image/jpeg'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Cada persona solo toca su carpeta: <uid>/<archivo> y <uid>/thumbs/<archivo>.
-- El upsert de la app necesita select + insert + update. Sin delete: ninguna historia borra aún.
create policy "fotos: ver las propias" on storage.objects
  for select to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "fotos: subir en la carpeta propia" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "fotos: reemplazar las propias" on storage.objects
  for update to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- La fila en foto es el marcador de "ya importada". Los asset_id en null no chocan en el unique.
alter table public.foto
  add column asset_id text check (char_length(asset_id) <= 300),
  add column ruta_miniatura text,
  add constraint foto_usuario_asset_unico unique (usuario_id, asset_id);

comment on column public.foto.asset_id is
  'Id de la foto en el dispositivo (AssetEntity.id). En iOS contiene "/".';
comment on column public.foto.url_imagen is
  'Ruta del archivo en el bucket fotos (no es una URL): <usuario_id>/<asset>.jpg. La URL firmada se pide al leer.';
comment on column public.foto.ruta_miniatura is
  'Ruta de la miniatura en el bucket fotos: <usuario_id>/thumbs/<asset>.jpg.';

-- finalizado_en sigue siendo el fin de todo el escaneo (importar, analizar, revisar etiquetas).
-- La importación tiene su propia marca; solo puede haber un escaneo abierto por persona.
alter table public.escaneo_galeria add column importacion_finalizada_en timestamptz;
create unique index escaneo_galeria_abierto_unico
  on public.escaneo_galeria(usuario_id) where finalizado_en is null;
