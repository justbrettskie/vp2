-- Review and run in the Supabase SQL Editor for project pnxyowqmwnsnwodlexug.
-- Health information is private: RLS restricts each row to its authenticated owner.

create table if not exists public.health_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  height_cm numeric,
  weight_kg numeric,
  age integer,
  gender text check (gender is null or gender in ('male','female')),
  resting_hr numeric,
  activity_level text not null default 'moderate' check (activity_level in ('sedentary','light','moderate','active','very_active')),
  health_conditions text[] not null default '{}',
  cycle_phase text check (cycle_phase is null or cycle_phase in ('menstrual','follicular','ovulation','luteal')),
  pregnancy_status text check (pregnancy_status is null or pregnancy_status in ('not_pregnant','first_trimester','second_trimester','third_trimester')),
  waist_cm numeric,
  hip_cm numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.activity_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  steps numeric not null default 0,
  duration_seconds numeric not null default 0,
  calories_burned numeric not null default 0,
  avg_heart_rate numeric,
  max_heart_rate numeric,
  bmi_at_time numeric,
  session_date date not null default current_date,
  device_type text not null default 'phone' check (device_type in ('phone','watch')),
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric not null default 0.99 check (amount >= 0),
  currency text not null default 'usd',
  status text not null default 'pending' check (status in ('pending','completed','failed')),
  payment_method text not null default 'stripe',
  stripe_checkout_session_id text unique,
  stripe_customer_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.health_profiles enable row level security;
alter table public.activity_sessions enable row level security;
alter table public.payments enable row level security;

create policy "Users can read their own health profiles" on public.health_profiles
  for select to authenticated using (auth.uid() = user_id);
create policy "Users can insert their own health profiles" on public.health_profiles
  for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can update their own health profiles" on public.health_profiles
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete their own health profiles" on public.health_profiles
  for delete to authenticated using (auth.uid() = user_id);

create policy "Users can read their own activity sessions" on public.activity_sessions
  for select to authenticated using (auth.uid() = user_id);
create policy "Users can insert their own activity sessions" on public.activity_sessions
  for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can update their own activity sessions" on public.activity_sessions
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete their own activity sessions" on public.activity_sessions
  for delete to authenticated using (auth.uid() = user_id);

-- Clients may read payment status, but cannot insert/update payment rows.
-- Only trusted server-side code using the service role may verify and update Stripe payments.
create policy "Users can read their own payments" on public.payments
  for select to authenticated using (auth.uid() = user_id);

create index if not exists health_profiles_user_updated_idx on public.health_profiles(user_id, updated_at desc);
create index if not exists activity_sessions_user_date_idx on public.activity_sessions(user_id, session_date desc);
create index if not exists payments_user_status_idx on public.payments(user_id, status);
