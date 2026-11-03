-- Ledger: run this once in Supabase (SQL Editor > New query > paste > Run).
-- Every row belongs to the signed-in user and can only be read or changed by them.

create table if not exists deposits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  amount numeric(14,2) not null check (amount > 0),
  note text not null default '',
  date timestamptz not null default now()
);

create table if not exists withdrawals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  amount numeric(14,2) not null check (amount > 0),
  note text not null default '',
  date timestamptz not null default now()
);

create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  vendor text not null default '',
  item text not null default '',
  amount numeric(14,2) not null check (amount > 0),
  date timestamptz not null default now()
);

create table if not exists creditors (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  amount numeric(14,2) not null check (amount >= 0),
  date timestamptz not null default now()
);

create table if not exists debtors (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  amount numeric(14,2) not null check (amount >= 0),
  date timestamptz not null default now()
);

-- Row-level security: each user only sees and edits their own rows.
do $$
declare t text;
begin
  foreach t in array array['deposits','withdrawals','payments','creditors','debtors'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "own rows" on %I', t);
    execute format(
      'create policy "own rows" on %I for all to authenticated
         using (user_id = (select auth.uid()))
         with check (user_id = (select auth.uid()))', t);
    execute format('create index if not exists %I on %I (user_id, date)', t || '_user_date_idx', t);
  end loop;
end $$;
