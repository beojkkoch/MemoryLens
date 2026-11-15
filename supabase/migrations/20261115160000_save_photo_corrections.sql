-- Correcciones de la persona en el detalle de una foto (HU-30): categoría, tipo de compra y
-- monto. Se guardan en las mismas columnas que escribe la IA, así que todo lo que las lee
-- (filtros, búsqueda, chat) usa lo corregido (CA4, CA6).

-- Guarda las correcciones de una foto, todo o nada. Corre con los permisos de quien llama
-- (security invoker), así que la RLS de foto impide corregir fotos ajenas.
--
-- Fuera de Factura los datos de compra se borran (HU-29, CA3). El tipo de compra corregido
-- reemplaza al anterior en las etiquetas, ya confirmado, porque lo escribió la persona (CA4).
create or replace function public.guardar_correccion_foto(
  p_foto_id uuid,
  p_categoria text,
  p_tipo_compra text default null,
  p_monto numeric default null,
  p_moneda text default null
) returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_categoria_id int;
  v_es_factura boolean;
  v_tipo_anterior text;
  v_tipo_compra text;
  v_monto numeric(12, 2);
  v_moneda text;
begin
  -- No se acepta una categoría vacía ni una fuera del catálogo (CA5).
  select id into v_categoria_id from categoria where nombre = btrim(p_categoria);
  if v_categoria_id is null then
    raise exception 'Categoría % no existe', p_categoria using errcode = '22023';
  end if;
  v_es_factura := btrim(p_categoria) = 'Factura';

  if v_es_factura then
    v_tipo_compra := nullif(left(btrim(p_tipo_compra), 40), '');
    if p_monto is not null then
      -- Positivo y con hasta 2 decimales (CA2, CA3).
      if p_monto <= 0 or p_monto <> round(p_monto, 2) then
        raise exception 'Monto % no válido', p_monto using errcode = '22023';
      end if;
      v_monto := p_monto;
      v_moneda := upper(btrim(p_moneda));
      if v_moneda is null or v_moneda !~ '^[A-Z]{3}$' then
        raise exception 'Moneda % no válida', p_moneda using errcode = '22023';
      end if;
    end if;
  end if;

  select tipo_compra into v_tipo_anterior from foto where id = p_foto_id;
  if not found then
    raise exception 'Foto % no encontrada', p_foto_id using errcode = 'P0002';
  end if;

  update foto
     set categoria_id = v_categoria_id,
         tipo_compra = v_tipo_compra,
         monto = v_monto,
         moneda = v_moneda
   where id = p_foto_id;

  -- Las etiquetas se escriben como en guardar_analisis_foto: en minúsculas y sin espacios
  -- de más.
  if v_tipo_anterior is distinct from v_tipo_compra and v_tipo_anterior is not null then
    delete from foto_etiqueta fe
     using etiqueta e
     where fe.foto_id = p_foto_id
       and fe.etiqueta_id = e.id
       and e.nombre = lower(btrim(v_tipo_anterior));
  end if;

  if v_tipo_compra is not null then
    insert into etiqueta (nombre)
    values (lower(v_tipo_compra))
    on conflict (nombre) do nothing;

    insert into foto_etiqueta (foto_id, etiqueta_id, confirmada)
    select p_foto_id, id, true from etiqueta where nombre = lower(v_tipo_compra)
    on conflict (foto_id, etiqueta_id) do update set confirmada = true;
  end if;
end;
$$;

revoke execute on function public.guardar_correccion_foto from public, anon;
grant execute on function public.guardar_correccion_foto to authenticated;
