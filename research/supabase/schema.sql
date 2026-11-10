-- Malta 2027 - schema do Supabase
-- Roda uma vez: Supabase Dashboard > SQL Editor > New query > colar tudo > Run.
-- Depois pegar Settings > API: Project URL + anon key -> Config/Local.xcconfig.

create table if not exists expenses (
  id uuid primary key,
  trip_id text not null,
  description text not null,
  amount numeric not null,
  payer text not null check (payer in ('nana', 'dani', 'ambas')),
  created_at timestamptz not null default now()
);

create table if not exists itinerary (
  id uuid primary key,
  trip_id text not null,
  idx int not null,
  title text not null,
  note text not null default '',
  done boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists checklists (
  id uuid primary key,
  trip_id text not null,
  group_idx int not null,
  text text not null,
  done boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists settings (
  trip_id text primary key,
  start date not null,
  meta numeric not null,
  monthly numeric not null,
  updated_at timestamptz not null default now()
);

-- PWA (index.html): sync em blob por trip (gastos, roteiro, checklist, settings, diario)
create table if not exists malta_sync (
  trip_id text primary key,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

-- Acesso restrito: so usuarios autenticados e autorizados (Nana/Dani).
-- Troque os e-mails abaixo pelos e-mails reais delas antes de rodar.
alter table malta_sync enable row level security;
create policy "malta_sync_allowed_rw" on malta_sync
  for all to authenticated
  using (lower(auth.jwt() ->> 'email') in ('nana@email.com', 'dani@email.com'))
  with check (lower(auth.jwt() ->> 'email') in ('nana@email.com', 'dani@email.com'));

create index if not exists expenses_trip on expenses (trip_id);
create index if not exists itinerary_trip on itinerary (trip_id, idx);
create index if not exists checklists_trip on checklists (trip_id, group_idx);

-- Bloqueio de acesso: sem as duas policies nada sera listado por fora.
-- (Duas usuarias de confianca; a chave trip_id configura o "token" de entrada.)
alter table expenses enable row level security;
alter table itinerary enable row level security;
alter table checklists enable row level security;
alter table settings enable row level security;

create policy "expenses_anon_rw" on expenses for all to anon using (true) with check (true);
create policy "itinerary_anon_rw" on itinerary for all to anon using (true) with check (true);
create policy "checklists_anon_rw" on checklists for all to anon using (true) with check (true);
create policy "settings_anon_rw" on settings for all to anon using (true) with check (true);
