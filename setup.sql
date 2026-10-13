-- Run once in Supabase > SQL Editor
create table if not exists kv(path text primary key, parent text, data jsonb, ts bigint);
create index if not exists kv_parent on kv(parent, ts);
alter table kv enable row level security;
drop policy if exists "read" on kv; drop policy if exists "ins" on kv; drop policy if exists "upd" on kv; drop policy if exists "del" on kv;
drop policy if exists "auth read" on kv; drop policy if exists "auth insert" on kv; drop policy if exists "auth update" on kv; drop policy if exists "auth delete" on kv;

-- everyone signed in (anonymous accounts count) can read; content is end-to-end encrypted
create policy "read" on kv for select to authenticated using (true);

-- profiles/<uid>: only the owner. chats/<id>: only a member (max 2).
-- chats/<id>/messages/<mid>: only the sender (data.from = your uid)
create policy "ins" on kv for insert to authenticated with check (
  path = 'profiles/'||auth.uid()::text
  or (path ~ '^chats/[^/]+$' and data->'members' ? auth.uid()::text and jsonb_array_length(data->'members')<=2)
  or (path ~ '^chats/[^/]+/messages/[^/]+$' and data->>'from' = auth.uid()::text));

create policy "upd" on kv for update to authenticated using (
  path = 'profiles/'||auth.uid()::text
  or (path ~ '^chats/[^/]+$' and (data->'members' ? auth.uid()::text or jsonb_array_length(data->'members')<2))
  or (path ~ '^chats/[^/]+/messages/[^/]+$' and data->>'from' = auth.uid()::text))
with check (
  path = 'profiles/'||auth.uid()::text
  or (path ~ '^chats/[^/]+$' and data->'members' ? auth.uid()::text and jsonb_array_length(data->'members')<=2)
  or (path ~ '^chats/[^/]+/messages/[^/]+$' and data->>'from' = auth.uid()::text));

create policy "del" on kv for delete to authenticated using (
  path = 'profiles/'||auth.uid()::text
  or (path ~ '^chats/[^/]+/messages/[^/]+$' and data->>'from' = auth.uid()::text));
