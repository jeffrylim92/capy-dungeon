-- Capy Dungeon Supabase schema bootstrap
-- Run this in Supabase SQL Editor.

begin;

create extension if not exists pgcrypto;

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique,
  email text unique,
  username text unique not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_users_email on users (email);

create table if not exists player_profiles (
  user_id uuid primary key references users(id) on delete cascade,
  display_name text not null,
  favorite_capy text default '',
  avatar_url text default '',
  country_code text default '',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists save_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  slot_name text not null default 'default',
  version int not null default 1,
  payload jsonb not null default '{}'::jsonb,
  checksum text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, slot_name)
);

create index if not exists idx_save_data_user on save_data (user_id);
create index if not exists idx_save_data_updated on save_data (updated_at desc);

create table if not exists leaderboards (
  id bigserial primary key,
  user_id uuid references users(id) on delete set null,
  username text not null,
  display_name text not null,
  mode text not null default 'survival',
  character text not null default '',
  kills int not null default 0,
  survive_sec double precision not null default 0,
  score double precision not null default 0,
  match_ts timestamptz not null default now(),
  rings jsonb not null default '{}'::jsonb,
  artifacts jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_leaderboards_mode_score on leaderboards (mode, score desc, match_ts asc);
create index if not exists idx_leaderboards_mode_kills on leaderboards (mode, kills desc, match_ts asc);
create index if not exists idx_leaderboards_mode_survive on leaderboards (mode, survive_sec desc, match_ts asc);
create index if not exists idx_leaderboards_character on leaderboards (character);
create index if not exists idx_leaderboards_user on leaderboards (user_id, created_at desc);

create table if not exists iap_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete set null,
  platform text not null,
  product_id text not null,
  order_id text,
  purchase_token text,
  transaction_id text,
  purchase_state text not null default 'pending',
  is_valid boolean not null default false,
  amount_micros bigint,
  currency_code text,
  purchased_at timestamptz,
  raw_receipt jsonb not null default '{}'::jsonb,
  verification_response jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform, purchase_token),
  unique (platform, order_id)
);

create index if not exists idx_iap_user on iap_receipts (user_id, created_at desc);
create index if not exists idx_iap_product on iap_receipts (product_id);

create table if not exists game_configs (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  description text default '',
  is_active boolean not null default true,
  updated_by text default 'system',
  updated_at timestamptz not null default now()
);

create table if not exists daily_rewards (
  user_id uuid not null references users(id) on delete cascade,
  reward_date date not null,
  reward_key text not null default 'daily_login',
  streak_count int not null default 0,
  status text not null default 'pending',
  reward_payload jsonb not null default '{}'::jsonb,
  claimed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, reward_date, reward_key)
);

create index if not exists idx_daily_rewards_status on daily_rewards (status, reward_date desc);

create table if not exists events (
  id bigserial primary key,
  user_id uuid references users(id) on delete set null,
  event_name text not null,
  event_type text not null default 'gameplay',
  source text not null default 'client',
  session_id text,
  event_ts timestamptz not null default now(),
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_events_user_time on events (user_id, event_ts desc);
create index if not exists idx_events_type_time on events (event_type, event_ts desc);
create index if not exists idx_events_name_time on events (event_name, event_ts desc);

commit;
