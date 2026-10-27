-- Permite que un usuario con sesión agregue intereses nuevos al catálogo durante el registro.

alter table public.interes
  add constraint interes_nombre_largo check (char_length(btrim(nombre)) between 1 and 40);

grant insert on public.interes to authenticated;

create policy "interes: agregar nuevos" on public.interes
  for insert to authenticated with check (true);
