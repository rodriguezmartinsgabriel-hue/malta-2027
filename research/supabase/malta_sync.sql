-- Malta 2027 (PWA) - aplicado em 2026-11-09 no projeto Supabase "malta-2027" (ref gdwcpziredxssaqwwxtk, sa-east-1).
-- So esta tabela e usada pela PWA. O schema.sql ao lado e do app nativo (pausado) e NAO foi aplicado.
create table if not exists public.malta_sync (
  trip_id text primary key,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.malta_sync enable row level security;

revoke all on public.malta_sync from anon;

create policy "malta_sync_allowed_rw" on public.malta_sync
  for all to authenticated
  using (lower((select auth.jwt()) ->> 'email') in ('nataliacprestes@gmail.com', 'danielalimags@outlook.com'))
  with check (lower((select auth.jwt()) ->> 'email') in ('nataliacprestes@gmail.com', 'danielalimags@outlook.com'));
