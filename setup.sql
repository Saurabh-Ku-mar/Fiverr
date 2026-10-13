create table if not exists kv(path text primary key, parent text, data jsonb, ts bigint);
create index if not exists kv_parent on kv(parent, ts);
alter table kv enable row level security;
create policy "auth read" on kv for select to authenticated using (true);
create policy "auth insert" on kv for insert to authenticated with check (true);
create policy "auth update" on kv for update to authenticated using (true);
create policy "auth delete" on kv for delete to authenticated using (true);
