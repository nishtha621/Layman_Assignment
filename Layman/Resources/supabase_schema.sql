-- ============================================================
-- Layman – Supabase Database Schema
-- ============================================================

-- saved_articles table
create table if not exists public.saved_articles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  article_id  text not null,
  article_data jsonb not null,
  saved_at    timestamptz not null default now(),

  -- prevent duplicate saves per user
  unique(user_id, article_id)
);

-- Index for fast per-user lookups
create index if not exists idx_saved_articles_user_id
  on public.saved_articles(user_id);

-- ============================================================
-- Row Level Security (RLS)
-- Users can only see and modify their own rows
-- ============================================================
alter table public.saved_articles enable row level security;

-- SELECT: users can only read their own saved articles
create policy "Users can view own saved articles"
  on public.saved_articles
  for select
  using (auth.uid() = user_id);

-- INSERT: users can only insert rows for themselves
create policy "Users can save articles"
  on public.saved_articles
  for insert
  with check (auth.uid() = user_id);

-- DELETE: users can only delete their own rows
create policy "Users can unsave articles"
  on public.saved_articles
  for delete
  using (auth.uid() = user_id);
