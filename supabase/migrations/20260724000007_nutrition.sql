-- Canonical food/ingredient reference data, populated by barcode lookups
-- (Open Food Facts) and cached so repeat scans don't re-hit the network.
create table public.food_items (
  id uuid primary key default extensions.uuid_generate_v4(),
  barcode text unique,
  name text not null,
  brand text,
  serving_size_g numeric(7, 2),
  calories_per_serving numeric(7, 2) not null,
  protein_g numeric(6, 2) not null default 0,
  carbs_g numeric(6, 2) not null default 0,
  fat_g numeric(6, 2) not null default 0,
  fiber_g numeric(6, 2),
  sugar_g numeric(6, 2),
  sodium_mg numeric(7, 2),
  image_url text,
  source text not null default 'manual' check (source in ('manual', 'openfoodfacts', 'ai_estimate')),
  created_at timestamptz not null default now()
);

create index food_items_barcode_idx on public.food_items (barcode);
create index food_items_name_trgm_idx on public.food_items using gin (name extensions.gin_trgm_ops);

alter table public.food_items enable row level security;

create policy "Food items are readable by any authenticated user"
  on public.food_items for select
  to authenticated
  using (true);

create policy "Any authenticated user can contribute a food item"
  on public.food_items for insert
  to authenticated
  with check (true);

-- A logged meal entry: one or more food_items with quantities, tied to a
-- meal type and timestamp. Supports an optional photo for visual logging
-- and AI meal-photo analysis.
create table public.meal_entries (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  logged_at timestamptz not null default now(),
  photo_url text,
  ai_analysis jsonb, -- structured output from the meal-analysis edge function
  notes text,
  created_at timestamptz not null default now()
);

create index meal_entries_user_logged_idx on public.meal_entries (user_id, logged_at desc);

alter table public.meal_entries enable row level security;

create policy "Users manage their own meal entries"
  on public.meal_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Line items within a meal entry (a meal can contain several foods).
create table public.meal_entry_items (
  id uuid primary key default extensions.uuid_generate_v4(),
  meal_entry_id uuid not null references public.meal_entries (id) on delete cascade,
  food_item_id uuid not null references public.food_items (id),
  quantity numeric(7, 2) not null default 1, -- multiple of serving_size_g
  calories numeric(7, 2) not null,
  protein_g numeric(6, 2) not null default 0,
  carbs_g numeric(6, 2) not null default 0,
  fat_g numeric(6, 2) not null default 0
);

alter table public.meal_entry_items enable row level security;

create policy "Users manage items on their own meal entries"
  on public.meal_entry_items for all
  using (exists (select 1 from public.meal_entries m where m.id = meal_entry_id and m.user_id = auth.uid()))
  with check (exists (select 1 from public.meal_entries m where m.id = meal_entry_id and m.user_id = auth.uid()));

create table public.water_logs (
  id uuid primary key default extensions.uuid_generate_v4(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  logged_at timestamptz not null default now(),
  amount_ml integer not null check (amount_ml > 0)
);

create index water_logs_user_logged_idx on public.water_logs (user_id, logged_at desc);

alter table public.water_logs enable row level security;

create policy "Users manage their own water logs"
  on public.water_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Daily macro/water targets, one active row per user (recomputed by the
-- daily-planner edge function or set manually).
create table public.nutrition_goals (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  calories integer not null,
  protein_g integer not null,
  carbs_g integer not null,
  fat_g integer not null,
  water_ml integer not null default 2500,
  is_ai_generated boolean not null default false,
  updated_at timestamptz not null default now()
);

create trigger set_nutrition_goals_updated_at
  before update on public.nutrition_goals
  for each row execute function public.set_updated_at();

alter table public.nutrition_goals enable row level security;

create policy "Users manage their own nutrition goals"
  on public.nutrition_goals for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
