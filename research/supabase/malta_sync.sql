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

-- 2026-11-09 (v3): privacidade por conta. Migration "malta_privacy_members_photos" aplicada no projeto.
-- Resumo do que ela criou (o SQL completo esta no historico de migrations do Supabase):
--   public.malta_members (email, who)      quem e Nana/Dani; cada uma so le a propria linha
--   malta_private.is_member()              funcao usada por todas as policies
--   public.malta_sync                      compartilhado; policy troca a lista fixa de e-mails por is_member()
--   public.malta_private (user_id, payload) pessoal; policy user_id = auth.uid() e is_member()
--   trigger malta_block_outsiders em auth.users  so e-mails de malta_members conseguem criar conta
--   bucket privado storage "malta-diary"   fotos do diario; select/insert/update/delete so para membros
--   malta_sync entrou na publication supabase_realtime
-- Para trocar ou incluir um e-mail: update/insert em public.malta_members.

-- 2026-11-09 (v4): migration "malta_docs_bucket".
--   bucket privado storage "malta-docs" (jpeg, png, pdf; 5 MB) para reservas e documentos
--   malta_private.can_use_doc(name): membro E (pasta "shared/" OU pasta "<auth.uid()>/")
--   policies select/insert/update/delete em storage.objects usando can_use_doc
-- O schema antigo do app nativo (tabelas abertas a anon) foi para _arquivo/ e NAO deve ser aplicado.
