-- Facturas (HU-09): tipo de compra, monto y moneda que la IA lee de una foto clasificada como
-- Factura. foto.tipo_compra y foto.monto ya existían; falta la moneda.

alter table public.foto
  add column moneda text;

-- Un monto sin moneda no se puede mostrar bien, así que van juntos o no van (CA2, CA3).
alter table public.foto
  add constraint foto_moneda_iso check (moneda ~ '^[A-Z]{3}$'),
  add constraint foto_monto_positivo check (monto > 0),
  add constraint foto_monto_con_moneda check ((monto is null) = (moneda is null)),
  add constraint foto_tipo_compra_largo check (char_length(btrim(tipo_compra)) between 1 and 40);

comment on column public.foto.tipo_compra is
  'Tipo de compra de una factura, por ejemplo Cafetería (HU-09). Null si no es factura o no se lee.';
comment on column public.foto.monto is
  'Monto total de una factura en su moneda (HU-09). Null si no es factura o no se lee con claridad.';
comment on column public.foto.moneda is
  'Código ISO 4217 de la moneda del monto, por ejemplo COP o USD (HU-09).';

-- La firma cambia, así que la versión de HU-08 se reemplaza.
drop function if exists public.guardar_analisis_foto(
  uuid, text, text, text, text[], extensions.vector, extensions.vector
);

-- Igual que en HU-08, más los datos de la factura. Solo una foto en la categoría Factura los
-- guarda (CA5): en cualquier otra quedan vacíos aunque la IA mande algo. El tipo de compra se
-- agrega también como etiqueta para que se pueda filtrar y buscar por él (CA4).
create function public.guardar_analisis_foto(
  p_foto_id uuid,
  p_titulo text,
  p_categoria text,
  p_descripcion text,
  p_etiquetas text[],
  p_embedding_imagen extensions.vector(768),
  p_embedding_texto extensions.vector(768),
  p_tipo_compra text default null,
  p_monto numeric default null,
  p_moneda text default null
) returns void
language plpgsql
security invoker
set search_path = public, extensions
as $$
declare
  v_usuario uuid;
  v_es_factura boolean := p_categoria = 'Factura';
  v_tipo_compra text;
  v_monto numeric(12, 2);
  v_moneda text;
  v_etiquetas text[];
begin
  if v_es_factura then
    v_tipo_compra := nullif(left(btrim(p_tipo_compra), 40), '');
    v_monto := round(p_monto, 2);
    v_moneda := upper(btrim(p_moneda));
    if v_monto is null or v_monto <= 0 or v_moneda is null or v_moneda !~ '^[A-Z]{3}$' then
      v_monto := null;
      v_moneda := null;
    end if;
  end if;

  update foto
     set titulo = left(btrim(p_titulo), 120),
         categoria_id = (select id from categoria where nombre = p_categoria),
         texto_alt = btrim(p_descripcion),
         tipo_compra = v_tipo_compra,
         monto = v_monto,
         moneda = v_moneda,
         embedding_imagen = p_embedding_imagen,
         embedding_texto = p_embedding_texto,
         estado_analisis = 'listo',
         analizada_en = now()
   where id = p_foto_id
  returning usuario_id into v_usuario;

  if v_usuario is null then
    raise exception 'Foto % no encontrada', p_foto_id using errcode = 'P0002';
  end if;

  -- Una etiqueta es la misma sin importar mayúsculas ni espacios de más. Un tipo de compra en
  -- null queda fuera por el filtro de largo.
  select coalesce(array_agg(distinct nombre), '{}')
    into v_etiquetas
    from (
      select lower(btrim(e)) as nombre
        from unnest(p_etiquetas || v_tipo_compra) as e
    ) t
   where char_length(nombre) between 1 and 50;

  insert into etiqueta (nombre)
  select unnest(v_etiquetas)
  on conflict (nombre) do nothing;

  delete from foto_etiqueta
   where foto_id = p_foto_id and not confirmada;

  insert into foto_etiqueta (foto_id, etiqueta_id)
  select p_foto_id, id from etiqueta where nombre = any (v_etiquetas)
  on conflict (foto_id, etiqueta_id) do nothing;

  update escaneo_galeria
     set fotos_analizadas = (
       select count(*) from foto
        where usuario_id = v_usuario and estado_analisis = 'listo'
     )
   where usuario_id = v_usuario and finalizado_en is null;
end;
$$;

revoke execute on function public.guardar_analisis_foto from public, anon;
grant execute on function public.guardar_analisis_foto to authenticated;

-- Las facturas que HU-08 ya analizó no tienen estos datos: vuelven a la cola una sola vez.
update public.foto
   set estado_analisis = 'pendiente'
 where estado_analisis = 'listo'
   and categoria_id = (select id from public.categoria where nombre = 'Factura');
