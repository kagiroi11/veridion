
-- Database schema
create table public.users table (
  id uuid not null default gen_random_uuid (),
  name text null,
  created_at timestamp with time zone not null default now(),
  constraint users table_pkey primary key (id)
) TABLESPACE pg_default;

create table public.transactions table (
  user_id uuid not null default gen_random_uuid (),
  amount numeric not null,
  type text null,
  category text null,
  date date null,
  constraint transactions table_pkey primary key (user_id)
) TABLESPACE pg_default;

create table public.streaks table (
  user_id uuid not null default gen_random_uuid (),
  streak_days smallint not null,
  last_emergency_withdrawal date null,
  constraint streaks table_pkey primary key (user_id)
) TABLESPACE pg_default;

create table public.notifications table (
  user_id uuid not null default gen_random_uuid (),
  message text not null,
  created_at timestamp with time zone null,
  constraint notifications table_pkey primary key (user_id)
) TABLESPACE pg_default;

create table public.leaderboard table (
  user_id uuid not null default gen_random_uuid (),
  saving_percentage numeric not null,
  leaderboard_score numeric null,
  constraint leaderboard table_pkey primary key (user_id)
) TABLESPACE pg_default;

create table public.financial_summary table (
  user_id uuid not null default gen_random_uuid (),
  total_income numeric not null,
  usable_balance numeric null,
  emergency_balance numeric null,
  debt_amount numeric null,
  constraint financial_summary table_pkey primary key (user_id)
) TABLESPACE pg_default;