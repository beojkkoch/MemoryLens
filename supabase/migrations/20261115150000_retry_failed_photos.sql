-- «Reintentar» las fotos no analizadas (HU-10, CA8): las fotos en 'error' vuelven a
-- 'pendiente' con sus 3 intentos de nuevo, así la siguiente corrida de analizar-fotos las
-- toma como a cualquier otra (título, categoría, etiquetas, embeddings y, si es factura,
-- tipo de compra y monto). Las ya analizadas no se tocan, así que no se gasta cuota en ellas.

-- Devuelve cuántas fotos volvieron a la cola. Solo toca las fotos de quien llama: la RLS ya
-- lo impide, y el filtro por auth.uid() lo deja explícito.
create or replace function public.reintentar_fotos_no_analizadas()
returns int
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_cuantas int;
begin
  update foto
     set estado_analisis = 'pendiente',
         intentos_analisis = 0,
         analizada_en = null
   where usuario_id = auth.uid() and estado_analisis = 'error';
  get diagnostics v_cuantas = row_count;
  return v_cuantas;
end;
$$;

revoke execute on function public.reintentar_fotos_no_analizadas from public, anon;
grant execute on function public.reintentar_fotos_no_analizadas to authenticated;
